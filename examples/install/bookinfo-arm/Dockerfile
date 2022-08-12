FROM  openjdk:alpine AS builder
RUN apk add maven 
COPY . ./ 
RUN mvn clean package liberty:create liberty:install-feature liberty:deploy liberty:package -Dinclude=minify,runnable


FROM openjdk:alpine
ENV WLP_JAR_EXTRACT_DIR /tmp
COPY --from=builder ./target/reviews.jar .
ARG service_version
ARG enable_ratings
ARG star_color
ENV SERVICE_VERSION ${service_version:-v1}
ENV ENABLE_RATINGS ${enable_ratings:-false}
ENV STAR_COLOR ${star_color:-black}

CMD ["java", "-jar", "reviews.jar"]
