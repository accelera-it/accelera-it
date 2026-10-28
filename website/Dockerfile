FROM httpd:2.4-alpine

# The stock config ignores .htaccess and leaves most of the modules it uses
# switched off, so enable them and let the .htaccess next to this file take effect.
RUN sed -i \
      -e 's/^#\(LoadModule rewrite_module\)/\1/' \
      -e 's/^#\(LoadModule headers_module\)/\1/' \
      -e 's/^#\(LoadModule expires_module\)/\1/' \
      -e 's/^#\(LoadModule deflate_module\)/\1/' \
      -e '/<Directory "\/usr\/local\/apache2\/htdocs">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
      conf/httpd.conf \
 && printf '\nServerName localhost\nServerTokens Prod\nServerSignature Off\n' >> conf/httpd.conf \
 && rm -rf htdocs/*

COPY . htdocs/

EXPOSE 80
