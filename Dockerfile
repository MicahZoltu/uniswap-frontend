# FROM node:14.20.0-bullseye-slim
FROM node@sha256:bc3ba9f44ea24daa94dfecb8e3aec9ea58229e5cb6610b7739162a07f5995ee7

# install wget, git and necessary certificates so we can install IPFS below
RUN apt update && apt install --yes --no-install-recommends wget git apt-transport-https ca-certificates && rm -rf /var/lib/apt/lists/*

# install IPFS
WORKDIR /home/root
RUN wget -qO - https://dist.ipfs.tech/kubo/v0.14.0/kubo_v0.14.0_linux-amd64.tar.gz | tar -xvzf - \
	&& cd kubo \
	&& ./install.sh \
	&& cd .. \
	&& rm -rf kubo
RUN ipfs init

# copy package.json and yarn install first so we can cache this layer (speeds up iteration significantly)
WORKDIR /app
COPY package.json /app/package.json
COPY yarn.lock /app/yarn.lock
RUN yarn install --frozen-lockfile --ignore-scripts

# copy the rest of the relevant source files and prepare, build, test the UI
COPY src/ /app/src/
COPY public/ /app/public/
COPY .env .env.production .eslintrc.json .prettierrc .prettierignore babel-plugin-macros.config.js codegen.yml craco.config.cjs cypress.config.ts cypress.release.config.ts lingui.config.ts prei18n-extract.js relay_thegraph.config.js relay.config.js tsconfig.json /app/
RUN yarn prepare
RUN yarn build
RUN yarn run craco test --watchAll=false

# add the build output to IPFS and write the hash to a file
RUN ipfs add --cid-version 1 --quieter --only-hash --recursive ./build > ipfs_hash.txt
# print the hash for good measure in case someone is looking at the build logs
RUN cat ipfs_hash.txt

# this entrypoint file will execute `ipfs add` of the build output to the docker host's IPFS API endpoint, so we can easily extract the IPFS build out of the docker image
RUN printf '#!/bin/sh\nipfs --api /ip4/`getent ahostsv4 host.docker.internal | grep STREAM | head -n 1 | cut -d \  -f 1`/tcp/5001 add --cid-version 1 -r ./build' >> entrypoint.sh
RUN chmod u+x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]
