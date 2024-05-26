# Invidious Helm chart

Easily deploy Invidious to Kubernetes.

## Installing Helm chart

```sh
# Add repo of Invidious helm charts
$ helm repo add invidious https://charts-helm.invidious.io
$ helm repo update

# Add PostgreSQL init scripts
$ kubectl create configmap invidious-postgresql-init \
  --from-file=../config/sql/channels.sql \
  --from-file=../config/sql/videos.sql \
  --from-file=../config/sql/channel_videos.sql \
  --from-file=../config/sql/users.sql \
  --from-file=../config/sql/session_ids.sql \
  --from-file=../config/sql/nonces.sql \
  --from-file=../config/sql/annotations.sql \
  --from-file=../config/sql/playlists.sql \
  --from-file=../config/sql/playlist_videos.sql

# Install Helm app to your Kubernetes cluster
$ helm install invidious invidious/invidious
```

## Upgrading

```sh
# Upgrading is easy, too!
$ helm upgrade invidious invidious/invidious
```

## Uninstall

```sh
# Get rid of everything (except database)
$ helm delete invidious

# To also delete the database, remove all invidious-postgresql PVCs
```
