FROM node:16

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install 
#yes i know, this add a new layer. 
COPY . .
RUN npm run seed
EXPOSE 3001
CMD [ "npm", "start" ]
