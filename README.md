# postgres-on-k8s
This repository is for evaluating PostgreSQL on Kubernetes.

What I'd like to do is explained in below slides.

https://www.slideshare.net/t8kobayashi/a-guide-of-postgresql-on-kubernetes

I am actually going to build a database cluster by using an auto-healing feature of Kubernetes.

## Architecture
This repository provides a simple PostgreSQL cluster with Rook as Cloud-Native Storage.
A PostgreSQL pod is deployed by StatefulSet. The replicas equals "1", so only one pod is running as a PostgreSQL instance.
Data redundancy is guaranteed by Rook. If one storage node is down, there isn't any problem because Rook(Ceph) makes data replicate.

## Instatll
See a blog post. https://qiita.com/tzkoba/items/56fdc60126d4b2350ad5
* Sorry, it's written by Japanese.
