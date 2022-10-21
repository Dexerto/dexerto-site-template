# Dexerto VVV site template

This tells VVV how to install the Dexerto WordPress project and set up Nginx.

 - [Overview](#overview)
 - [ARM Mac setup](#arm-mac-setup)
 - [Configuration Options](#configuration-options)
 - [Examples](#examples)

## Overview

This template will allow you to create the Dexerto WordPress dev environment using only `config/config.yml`.

The Nginx configuration for this site can be overriden by creating a `provision/vvv-nginx-custom.conf`.

## ARM Mac Setup 

- Install and set up [homebrew](https://brew.sh/).
- In the terminal type the following commands:
  - ``` brew install parallels```
  - ``` brew install vagrant```
- Open up parallels and sign up to a pro or business account.
- Follow the [vvv installation instructions](https://varyingvagrantvagrants.org/docs/en-US/installation/).
- Once the vvv-local file is installed, navigate to vvv-local/config/config.yml.
  - Add the following lines into where the sites are located:
  - ```
    dexerto:
    repo: git@github.com:Dexerto/dexerto-site-template.git
    hosts:
      - dexerto.test
  - ***WARNING*** indentation is critical for yaml files.
- In the terminal navigate to vvv-local/www/dexerto/public_html.
- Type the following command ```vagrant plugin install vagrant-parallels```.
- Add an auth.json file to vvv-local/www/dexerto/public_html with the correct keys.
- Type ```vagrant up```
- ***Warning*** any changes made to the vagrant config must be followed by ```vagrant reload --provision```
- The following file vvv-local/www/dexerto/public_html/wp-content/mu-plugins/000-boxuk-init.php line 17-19 may contain code that breaks the provisioner, comment this out and run ```vagrant reload --provision```.

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
