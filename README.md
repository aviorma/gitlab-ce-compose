# Docker compose Gitlab CE


## Requirements

- Follow Gitlab installation system [requirements](https://docs.gitlab.com/ee/install/requirements.html)
- A dedicated disk mounted on /opt or LVM management for that path.
- Docker installed. [guide](https://docs.docker.com/engine/install/)
- Docker compose 3 installed. [guide](https://docs.docker.com/compose/install/)
- Root privileges during the deployment steps.

## Components

The main docker compose file `docker-compose.yml` for the official [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce) Gitlab CE image, with seperation of Redis, Postgres and Gitlab runner services.

- Gitlab CE [gitlab-ce](https://hub.docker.com/r/gitlab/gitlab/) instance
- Gitlab Runner [gitlab-runner](https://hub.docker.com/r/gitlab/gitlab-runner/) instance
- Postgres [postgres](https://hub.docker.com/_/postgres/) docker image
- Redis [redis](https://hub.docker.com/_/redis/) docker image

Can be improved with adding nginx-proxy for direct limited access [nginx-proxy](https://github.com/jwilder/nginx-proxy) with SSL via letsencrypt.

## Deployment configuration
- We use the envsubst tool to make a template for the gitlab.rb file, using the given configuration and the docker-compose file.

   ```bash
   > cat .env
      ## Images
      DOCKER_IMAGE=gitlab/gitlab-ce
      GITLAB_CE_VERSION=16.6.1-ce.0
      GITLAB_RUNNER_VERSION=alpine-v16.6.1
      POSTGRES_VERSION=16.1-alpine
      REDIS_VERSION=4-alpine

      ## Defaults
      GITLAB_NGINX_INSECURED_PORT=80
      GITLAB_NGINX_SECURED_PORT=443
      GITLAB_HOST=localhost
      REGISTRY_HOST=postgres
      TZ=Asia/Jerusalem
      POSTGRES_HOST_AUTH_METHOD=trust

      ## Creds - Move to vault / secret manager
      POSTGRES_PASSWORD=*************
      GITLAB_ROOT_PASSWORD=*************
      GITLAB_DEFAULT_TOKEN=*************
   ```
## Quickstart

- Clone the repository mounted on dedicated block device in /opt/gitlab, template the gitlab.rb then start the cluster with docker-compose.
- A post script will create the users and groups then it will assign the relevant permissions through Gitlab API.

   ```bash
   sudo su -
   git clone git@github.com:aviorma/gitlab-ce-compose.git /opt/gitlab; cd $_
   find volumes/ -type f -name '.gitkeep' -exec rm -f {} \;
   chmod -R 0755 /opt/gitlab/volumes

   set -a && source .env &&  envsubst < config/gitlab.rb > "volumes/config/gitlab.rb"
   docker-compose up -d
   bash scripts/users-and-groups.sh
   ```

### Access Gitlab UI
```bash
https://IP_ADDRESS/
```

### Check the folders tree that has been cerated

```bash
> find ./volumes/ -maxdepth 1 -type d
./volumes/
./volumes/config
./volumes/redis
./volumes/runner
./volumes/postgres
./volumes/logs
./volumes/data
```

### Check Gitlab services status

```bash
/usr/bin/docker exec -t gitlab gitlab-ctl status
```

### Reconfigure Gitlab application with gitlab.rb.

```bash
/usr/bin/docker exec -t gitlab gitlab-ctl reconfigure
```

## Configure cron to make daily backups
1. Switch to root and edit the cron list

   ```shell
   sudo su -
   crontab -e
   ```

1. There, add the following line to schedule the backup for everyday at 2 AM:

   ```plaintext
   0 2 * * * /usr/bin/docker exec -t gitlab gitlab-backup create SKIP=db
   ```
   This can be improved by adding an S3 bucket configuration to automatically upload the back to the S3 bucket.

## Configuration

- [gitlab.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)

## Related Documentation

- [Template files with envsubst](https://www.baeldung.com/linux/envsubst-command#:~:text=Basic%20Features%20of%20envsubst,replaced%20by%20an%20empty%20string.)
- [GitLab Docker images](https://docs.gitlab.com/omnibus/docker/)
- [GitLab CI Docker images](https://docs.gitlab.com/ce/ci/docker/using_docker_images.html)
- [Gitlab backup](https://docs.gitlab.com/omnibus/settings/backups.html)
- [Using a non-bundled web-server](https://docs.gitlab.com/omnibus/settings/nginx.html#using-a-non-bundled-web-server)

