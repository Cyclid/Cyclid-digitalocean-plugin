Cyclid Digitalocean plugin
==========================

This is a Builder plugin for Cyclid which creates build hosts using [Digitalocean](https://www.digitalocean.com/).

The plugin is built on top of Digitalocean's own [DropletKit Gem](https://rubygems.org/gems/droplet_kit), which provides a Ruby interface to the Digitalocean v2 API.

# Installation

Install the plugin and restart Cyclid & Sidekiq

```
$ gem install cyclid-digitalocean-plugin
$ service cyclid restart
$ service sidekiq restart
```

# Configuration

| Option | Required? | Default | Notes |
| --- | --- | --- | --- |
| access\_token | Y | _None_ | Your Digitalocean API access token |
| region | N | nyc1 | Region to create build instances |
| size | N | 512mb | Instance size |
| ssh\_private\_key | N | `/etc/cyclid/id_rsa_build` | Instance SSH private key |
| ssh\_public\_key | N | `/etc/cyclid/id_rsa_build.pub` | Instance SSH public key |
| ssh\_key\_name | N | cyclid-build | Instance SSH key name |
| instance\_name | N | cyclid-build | Cyclid build host name prefix |

The only option which is required is _access\_token_. This should be a valid Digitalocean access token [which you have created for your account.](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2)

## SSH keys

The Digitalocean plugin will attempt to find, and create if required, a dedicated SSH key which it will use when created droplets. By default Cyclid will use a key called "cyclid-build"; you can change this name using the _ssh\_key\_name_ option if you wish.

By default the keypair `/etc/cyclid/id_rsa_build` (private) and `/etc/cyclid/id_rsa_build.pub` (public) will be used. You can set paths to a different keypair using the _ssh\_private\_key_ and _ssh\_public\_key_ options.

The private key is only used if Cyclid can not find a key that matches _ssh\_key\_name_: if you wish, you can add the private key to your Digitalocean account yourself, and not provide it for use by Cyclid.

# Usage

Install & configure the plugin as above, and configure Cyclid to use the plugin for it's Builder by setting the _builder_ option to "digitalocean".

## Example

Create `1gb` sized instances in the SFO2 region:

```yaml
server:
  ...
  builder: digitalocean
  ...
  plugins:
    digitalocean:
      access_token: <API access token>
      region: sfo2
      size: 1gb
```
