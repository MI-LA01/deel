# syntax=docker/dockerfile:1
#Building the app without the dev dependencies. 
FROM node:16 AS builder
LABEL maintainer "agruet[at].."

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
RUN npm run seed

# Added a stage for testing is a good
# FROM .. as test 
# npm test

# Exposing the service from a distroless optimise the size. 
# 
FROM gcr.io/distroless/nodejs:16 AS service
COPY --from=builder /usr/src/app /app
WORKDIR /app
EXPOSE 3001
CMD [ "./src/server.js" ]