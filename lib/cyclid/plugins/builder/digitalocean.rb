# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'droplet_kit'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Digitalocean build host
      class DigitaloceanHost < BuildHost
        # SSH is the only acceptable Transport
        def transports
          ['ssh']
        end
      end

      # Digitalocean builder. Uses the Digitalocean API to obtain a build host instance.
      class Digitalocean < Builder
        def initialize
          @config = load_digitalocean_config(Cyclid.config.plugins)
          @client = DropletKit::Client.new(access_token: @config[:access_token])
        end

        # Create & return a build host
        def get(args = {})
          args.symbolize_keys!

          Cyclid.logger.debug "digitalocean: args=#{args}"

          # If there is one, split the 'os' into a 'distro' and 'release'
          if args.key? :os
            match = args[:os].match(/\A(\w*)_(.*)\Z/)
            distro = match[1] if match
            release = match[2] if match
          else
            # No OS was specified; use the default
            # XXX Defaults should be configurable
            distro = 'ubuntu'
            release = 'trusty'
          end

          release_version = case release
                            when 'trusty'
                              '14-04'
                            end

          begin
            # Find the build key, if it exists
            build_key = nil
            all_keys = @client.ssh_keys.all
            all_keys.each do |key|
              build_key = key if key.name == @config[:ssh_key_name]
            end
            Cyclid.logger.debug "build_key=#{build_key.inspect}"

            # If the key doesn't exist, create it
            if build_key.nil?
              pubkey = File.read(@config[:ssh_public_key])
              key = DropletKit::SSHKey.new(name: @config[:ssh_key_name],
                                           public_key: pubkey)
              build_key = @client.ssh_keys.create(key)
              Cyclid.logger.debug "build_key=#{build_key.inspect}"
            end

            # Create the Droplet
            droplet = DropletKit::Droplet.new(name: create_name,
                                              region: @config[:region],
                                              image: "#{distro}-#{release_version}-x64",
                                              size: @config[:size],
                                              ssh_keys: [build_key.id])
            created = @client.droplets.create droplet

            # Wait for it to become active; wait a maximum of 1 minute, polling
            # every 2 seconds.
            for timeout in 0..29
              created = @client.droplets.find(id: created.id.to_s)
              break if created.status == 'active'

              Cyclid.logger.debug "Waiting for instance #{created.id.to_s} to become 'active'..."
              sleep 2
            end
            Cyclid.logger.debug "created=#{created.inspect}"

            unless created.status == 'active'
              @client.droplets.delete(id: created.id)

              raise 'failed to create build host: did not become active within 1 minute. ' \
                    "Status is #{created.status}" \
            end

            buildhost = DigitaloceanHost.new(name: created.name,
                                             host: created.networks.v4.first.ip_address,
                                             id: created.id,
                                             username: 'root',
                                             workspace: '/root',
                                             key: @config[:ssh_private_key],
                                             distro: distro,
                                             release: release)
          rescue StandardError => ex
            Cyclid.logger.error "couldn't get a build host from Digitalocean: #{ex}"
            raise "digitalocean failed: #{ex}"
          end

          # XXX hax; the SSH transport seems to cope poorly; make the SSH
          # transport more resiliant to SSH connection errors
          sleep 30

          Cyclid.logger.debug "digitalocean buildhost=#{buildhost.inspect}"
          buildhost
        end

        # Destroy the build host
        def release(_transport, buildhost)
          begin
            @client.droplets.delete(id: buildhost[:id])
          rescue StandardError => ex
            Cyclid.logger.error "Digitalcoean destroy timed out: #{ex}"
          end
        end

        # Register this plugin
        register_plugin 'digitalocean'

        private

        # Load the config for the Digitalocean plugin and set defaults if they're not
        # in the config
        def load_digitalocean_config(config)
          config.symbolize_keys!

          do_config = config[:digitalocean] || {}
          do_config.symbolize_keys!
          Cyclid.logger.debug "config=#{do_config}"

          raise 'the Digitalocean API access token must be provided' \
            unless do_config.key? :access_token

          # Set defaults
          #do_config[:] = '' unless do_config.key? :
          do_config[:region] = 'nyc1' unless do_config.key? :region
          do_config[:size] = '512mb' unless do_config.key? :size
          do_config[:ssh_private_key] = File.join(%w(/ etc cyclid id_rsa_build)) \
            unless do_config.key? :ssh_private_key
          do_config[:ssh_public_key] = File.join(%w(/ etc cyclid id_rsa_build.pub)) \
            unless do_config.key? :ssh_public_key
          do_config[:ssh_key_name] = 'cyclid-build' \
            unless do_config.key? :ssh_key_name
          do_config[:instance_name] = 'cyclid-build' \
            unless do_config.key? :instance_name

          return do_config
        end

        def create_name
          base = @config[:instance_name]
          "#{base}-#{SecureRandom.hex(16)}"
        end
      end
    end
  end
end
