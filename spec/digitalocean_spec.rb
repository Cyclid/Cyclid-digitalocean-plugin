# frozen_string_literal: true
require 'spec_helper'

class FakeSSHKey
  def name
    'cyclid-build'
  end

  def id
    '1234567890'
  end
end

class FakeSSHKeysResource
  def all
    [FakeSSHKey.new]
  end
end

class FakeV4Network
  def ip_address
    '127.0.0.'
  end
end

class FakeNetworkResource
  def v4
    [FakeV4Network.new]
  end
end

class FakeDroplet
  def id
    'abcdef'
  end

  def status
    'active'
  end

  def name
    'fake'
  end

  def networks
    @network_resource ||= FakeNetworkResource.new
  end
end

class FakeDropletResource
  def create(*args)
    FakeDroplet.new
  end

  def find(*args)
    FakeDroplet.new
  end

  def delete(*args)
    true
  end
end

class FakeClient
  def droplets
    @droplet_resource ||= FakeDropletResource.new
  end

  def ssh_keys
    @ssh_keys_resource ||= FakeSSHKeysResource.new
  end
end

describe Cyclid::API::Plugins::Digitalocean do
  it 'should create an instance' do
    expect{ Cyclid::API::Plugins::Digitalocean.new }.to_not raise_error
  end

  let :subject do
    Cyclid::API::Plugins::Digitalocean.new
  end

  let :client do
    FakeClient.new
  end

  before do
    droplet_kit = class_double(DropletKit::Client).as_stubbed_const
    allow(droplet_kit).to receive(:new).and_return(client)
  end

  context 'obtaining a build host' do
    it 'returns a host when called with default arguments' do
      buildhost = nil
      expect{ buildhost = subject.get }.to_not raise_error
      expect(buildhost).to be_an_instance_of(Cyclid::API::Plugins::DigitaloceanHost)
      expect(buildhost.transports).to match_array(['ssh'])
    end

    it 'returns a host when called with a Debian codename' do
      buildhost = nil
      expect{ buildhost = subject.get(os: 'debian_jessie') }.to_not raise_error
      expect(buildhost).to be_an_instance_of(Cyclid::API::Plugins::DigitaloceanHost)
    end

    it 'returns a host when called with an Ubuntu version' do
      buildhost = nil
      expect{ buildhost = subject.get(os: 'ubuntu_14-04') }.to_not raise_error
      expect(buildhost).to be_an_instance_of(Cyclid::API::Plugins::DigitaloceanHost)
    end

    it 'returns a host when called with a non-Debian & non-Ubuntu OS' do
      buildhost = nil
      expect{ buildhost = subject.get(os: 'centos-7-0') }.to_not raise_error
      expect(buildhost).to be_an_instance_of(Cyclid::API::Plugins::DigitaloceanHost)
    end
  end

  context 'destroying a build host' do
    it 'destroys the instance' do
      expect{ subject.release(nil, {id: 'abcdef'}) }.to_not raise_error
    end
  end
end
