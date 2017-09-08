include:
  - nginx.ng.service

{% set certificates_path = salt['pillar.get']('nginx:ng:certificates_path', '/etc/nginx/ssl') %}

{% if salt.pillar.get('nginx:ng:dh_contents') %}
create_nginx_dhparam_key:
  file.managed:
    - name: /etc/nginx/ssl/dhparam.pem
    - contents_pillar: nginx:ng:dh_contents
    - makedirs: True
{% elif salt.pillar.get('nginx:ng:dh_keygen', False) %}
generate_nginx_dhparam_key:
  file.directory:
    - name: /etc/nginx/ssl
    - makedirs: True
  cmd.run:
    - name: openssl dhparam -out dhparam.pem {{ salt.pillar.get('nginx:ng:dh_keysize', 2048) }}
    - cwd: /etc/nginx/ssl
    - creates: /etc/nginx/ssl/dhparam.pem
{% endif %}

{%- for domain in salt['pillar.get']('nginx:ng:certificates', {}).keys() %}

nginx_{{ domain }}_ssl_certificate:
  file.managed:
    - name: {{ certificates_path }}/{{ domain }}.crt
    - makedirs: True
    - contents_pillar: nginx:ng:certificates:{{ domain }}:public_cert
    - watch_in:
      - service: nginx_service

{% if salt['pillar.get']("nginx:ng:certificates:{}:private_key".format(domain)) %}
nginx_{{ domain }}_ssl_key:
  file.managed:
    - name: {{ certificates_path }}/{{ domain }}.key
    - mode: 600
    - makedirs: True
    - contents_pillar: nginx:ng:certificates:{{ domain }}:private_key
    - watch_in:
      - service: nginx_service
{% endif %}
{%- endfor %}
