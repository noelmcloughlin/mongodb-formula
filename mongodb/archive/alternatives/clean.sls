# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

  {%- if grains.kernel|lower == 'linux' and m.linux.altpriority|int > 0 and grains.os_family != 'Arch' %}
      {%- if 'wanted' in p and m.wanted and 'component' in m.wanted and m.wanted.component %}
          {%- for name in m.wanted.component %}
              {%- if 'path' in m.pkg.component[name] %}
                  {%- if 'commands' in m.pkg.component[name] and m.pkg.component[name]['commands'] is iterable %}
                      {%- for cmd in m.pkg.component[name]['commands'] %}

mongodb-archive-alternatives-clean-{{ name }}-{{ cmd }}:
  alternatives.remove:
    - unless: {{ m.pkg.use_upstream_repo }}
    - name: link-mongodb-{{ name }}-{{ cmd }}
    - path: {{ m.pkg.component[name]['path'] }}/{{ cmd }}
    - onlyif: update-alternatives --get-selections |grep ^mongodb-{{ name }}-{{ cmd }}

                      {%- endfor %}
                  {%- endif %}
              {%- endif %}
          {%- endfor %}
      {%- endif %}
  {%- endif %}
