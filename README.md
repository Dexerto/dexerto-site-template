# Dexerto VVV site template

This tells VVV how to install the Dexerto WordPress project and set up Nginx.

 - [Overview](#overview)
 - [Configuration Options](#configuration-options)
 - [Examples](#examples)

## Overview

This template will allow you to create the Dexerto WordPress dev environment using only `config/config.yml`.

The Nginx configuration for this site can be overriden by creating a `provision/vvv-nginx-custom.conf`.

## Configuration Options


| Key                      | Default                    | Description                                                                                                                                                                                                                                                                        |
|--------------------------|----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `admin_email`            | `webdev@dexerto.com`         | The email address of the initial admin user                                                                                                                                                                                                                                        |
| `admin_password`         | `password`                 | The password for the initial admin user                                                                                                                                                                                                                                            |
| `admin_user`             | `dexertoadmin`                    | The name of the initial admin user                                                                                                                                                                                                                                                 |
| `db_name`                | The sites name             | The name of the MySQL database to create and install to                                                                                                                                                                                                                           |
| `db_prefix`              | `wp_`                      | The WP table prefix                                                                                                                                                                                                                                                               |
| `delete_default_plugins` | `false`                    | Deletes the Hello Dolly and Akismet plugins on install                                                                                                                                                                                                                             |
| `install_test_content`   | `false`                    | When first installing WordPress, run the importer and import standard test content from github.com/poststatus/wptest                                                                                                                                                               |
| `public_dir`             | `public_html`              | Change the default folder inside the website's folder with the WP installation            |
| `live_url`               |                            | The production site URL, this tells Nginx to redirect requests for assets to the production server if they're not found. This prevents the need to store those assets locally.                                                                                                     |
| `site_title`             | Dexerto | The main name/title of the site, defaults to `Dexerto`                                                                                                                                                                                                                       |
| `dexerto_repo`             | git@github.com:humet/dexerto.git | The SSH link to the Dexerto project repo                                                                                                                                                                                                                       |

## Examples

### The Minimum Required Configuration

The default Dexerto WordPress site:

```yaml
  dexerto:
    repo: git@github.com:Dexerto/dexerto-site-template.git
    hosts:
      - dexerto.docker.hq.boxuk.net
```

| Setting    | Value        |
|------------|--------------|
| Domain     | my-site.test |
| Site Title | my-site.test |
| DB Name    | dexerto      |

## Configuration Options

```yaml
hosts:
    - foo.test
    - bar.test
    - baz.test
```

Defines the domains and hosts for VVV to listen on.
The first domain in this list is your sites primary domain.

Other parameters available:

```yaml
custom:
    admin_user: admin # Only on install of WordPress
    admin_password: password # Only on install of WordPress
    admin_email: admin@local.test # Only on install of WordPress
    live_url: http://example.com # Redirect any uploads not found locally to this domain
```
