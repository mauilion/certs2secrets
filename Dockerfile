FROM gliderlabs/alpine:latest
ADD https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl /usr/local/bin/kubectl
ADD https://github.com/JulienBalestra/kube-csr/releases/download/0.5.0/kube-csr /usr/local/bin/kube-csr
COPY manage_certs.sh /manage_certs.sh
RUN apk-install openssl bash iputils bind-tools curl ca-certificates
RUN set -x && \
    chmod +x /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kube-csr && \
    chmod +x /manage_certs.sh

CMD ["/bin/bash", "-x", "manage_certs.sh"]
