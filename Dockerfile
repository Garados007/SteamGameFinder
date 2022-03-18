FROM ubuntu:latest as elm-builder
RUN apt-get -qq update -y && \
    apt-get -qq upgrade -y && \
    apt-get install wget -y && \
    wget -q https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
        -O elm.gz && \
    gunzip elm.gz && \
    chmod +x elm && \
    mv elm /bin/
WORKDIR /src
COPY ui/elm.json /src/
COPY ui/src /src/src
RUN mkdir /content && \
    rm -r /src/src/Debug && \
    elm make --optimize --output=/content/index.js src/Main.elm

FROM node:latest as js-compressor
RUN npm install uglify-js --global
WORKDIR /content
COPY --from=elm-builder /content/index.js /content/source.js
RUN uglifyjs \
        source.js \
        --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,unsafe_comps,unsafe' \
        --mangle 'reserved=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9]' \
        --output index.js && \
    rm source.js

FROM mcr.microsoft.com/dotnet/sdk:6.0 as builder
WORKDIR /src
COPY SteamGameFinder/ .
RUN dotnet build --nologo -c RELEASE \
        SteamGameFinder.csproj && \
    dotnet publish --nologo -c RELEASE -o /app \
        SteamGameFinder.csproj

FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
COPY --from=builder /app /app
COPY ui/css /app/ui/css
COPY ui/index.html /app/ui/index.html
COPY --from=js-compressor /content/index.js /app/ui/index.js
# this is the cache directory. Map it to something outside to keep cache between restarts
RUN mkdir -p /app/cache
RUN sed -i "s@/index.js@/ui/index.js@" /app/ui/index.html && \
    sed -i "s@/api/api/@/api/@g" /app/ui/index.js
EXPOSE 8000
CMD [ "dotnet", "/app/SteamGameFinder.dll" ]
