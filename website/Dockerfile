FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/
COPY security.html /usr/share/nginx/html/
COPY privacy.html /usr/share/nginx/html/
COPY terms.html /usr/share/nginx/html/
COPY handyman.html /usr/share/nginx/html/
COPY handyman.css /usr/share/nginx/html/
COPY handyman.js /usr/share/nginx/html/
COPY handyman-quote.html /usr/share/nginx/html/
COPY handyman-quote.css /usr/share/nginx/html/
COPY handyman-quote.js /usr/share/nginx/html/
COPY handyman-visit.html /usr/share/nginx/html/
COPY handyman-visit.css /usr/share/nginx/html/
COPY handyman-visit.js /usr/share/nginx/html/
COPY handyman-visit-sw.js /usr/share/nginx/html/
COPY handyman-visit.webmanifest /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY og-image.png /usr/share/nginx/html/
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
