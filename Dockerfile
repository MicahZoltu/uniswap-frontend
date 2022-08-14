# syntax=docker/dockerfile:1.4

# FROM node:16.16.0-bullseye-slim
FROM node@sha256:cda7229eb72b7534396e7b58ba5b9f2454aee188317e058cbbf22686e5d07e2f

RUN apt update && apt install --yes --no-install-recommends wget git apt-transport-https ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /home/root
RUN wget -qO - https://dist.ipfs.tech/kubo/v0.14.0/kubo_v0.14.0_linux-amd64.tar.gz | tar -xvzf - \
	&& cd kubo \
	&& ./install.sh \
	&& cd .. \
	&& rm -rf kubo
RUN ipfs init

WORKDIR /app
COPY --link package.json /app/package.json
COPY --link yarn.lock /app/yarn.lock
RUN yarn install --frozen-lockfile --ignore-scripts

COPY --link src/ /app/src/
COPY --link public/ /app/public/
COPY --link .env .env.production .eslintrc.json .prettierrc .prettierignore babel-plugin-macros.config.js codegen.yml craco.config.cjs cypress.config.ts cypress.release.config.ts lingui.config.ts prei18n-extract.js tsconfig.json /app/
RUN yarn prepare
RUN yarn build
RUN ipfs add --cid-version 1 --recursive ./build

COPY --link <<EOF entrypoint.sh
#!/bin/sh
ipfs --api /ip4/`getent ahostsv4 host.docker.internal | grep STREAM | head -n 1 | cut -d ' ' -f 1`/tcp/5001 add --cid-version 1 -r ./build
EOF
RUN chmod u+x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]
