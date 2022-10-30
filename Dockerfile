# Building and testing the app with dev dependencies
#
FROM node:16 as builder
LABEL maintainer "agruet[at].."
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .

# Building for production
#
FROM node:16 AS tester
LABEL maintainer "agruet[at].."

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run seed 
RUN npm run test 

# Exposing the service from a distroless optimise the size. 
# 
FROM gcr.io/distroless/nodejs:16 AS service
COPY --from=builder /usr/src/app /app
WORKDIR /app
EXPOSE 3001
CMD [ "./src/server.js" ]