FROM httpd:2.4-alpine

# The stock config ignores .htaccess and leaves most of the modules it uses
# switched off, so enable them and let the .htaccess next to this file take effect.
# Logs go to files under logs/ (mounted as a volume) instead of stdout.
RUN sed -i \
      -e 's/^#\(LoadModule rewrite_module\)/\1/' \
      -e 's/^#\(LoadModule headers_module\)/\1/' \
      -e 's/^#\(LoadModule expires_module\)/\1/' \
      -e 's/^#\(LoadModule deflate_module\)/\1/' \
      -e '/<Directory "\/usr\/local\/apache2\/htdocs">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
      -e 's#^ErrorLog /proc/self/fd/2#ErrorLog logs/error_log#' \
      -e 's#^\(\s*\)CustomLog /proc/self/fd/1 common#\1CustomLog logs/access_log combined#' \
      conf/httpd.conf \
 && printf '\nServerName localhost\nServerTokens Prod\nServerSignature Off\n' >> conf/httpd.conf \
 && rm -rf htdocs/*

COPY . htdocs/

EXPOSE 80
