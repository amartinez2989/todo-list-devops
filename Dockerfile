FROM node:18.9.0-alpine
RUN mkdir /app
WORKDIR /app
USER root
RUN apk add --no-cache bash && \
    mkdir -p /etc/todos && \
    chown node:node /etc/todos
COPY package.json .
RUN npm install

# archivos de aplicación
COPY src/ ./src
COPY spec/ ./spec
USER node
EXPOSE 3000
CMD [ "npm", "start" ]