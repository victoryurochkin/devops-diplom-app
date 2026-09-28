FROM nginx@sha256:0985e772fb9f729e6fa0980da05fca5d9c468e870eed43071545afa9d2e27d94

COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

USER nginx
EXPOSE 8080
STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
