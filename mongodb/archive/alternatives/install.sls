# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

{%- if grains.kernel|lower == 'linux' and m.linux.altpriority|int > 0 and grains.os_family != 'Arch' %}
    {%- set sls_archive_install = tplroot ~ '.archive.install' %}

include:
  - {{ sls_archive_install }}

    {%- if 'wanted' in m and m.wanted and 'component' in m.wanted and m.wanted.component %}
        {%- for name in m.wanted.component %}
            {%- if 'path' in m.pkg.component[name] %}
                {%- if 'commands' in m.pkg.component[name] and m.pkg.component[name]['commands'] is iterable %}
                    {%- set dir_symlink = m.dir.symlink ~ '/bin' %}
                    {%- if 'service' in m.pkg.component[name] %}
                        {%- set dir_symlink = m.dir.symlink ~ '/sbin' %}
                    {%- endif %}
                    {%- for cmd in m.pkg.component[name]['commands'] %}

mongodb-archive-alternatives-install-{{ name }}-{{ cmd }}:
  cmd.run:
    - name: update-alternatives --install {{ dir_symlink }}/{{ cmd }} link-mongodb-{{ name }}-{{ cmd }} {{ m.pkg.component[name]['path'] }}/{{ cmd }} {{ m.linux.altpriority }}  # noqa 204
    - unless:
      -  {{ grains.os_family not in ('Suse',) }}
      - {{ m.pkg.use_upstream_repo }}
    - require:
      - sls: {{ sls_archive_install }}
  alternatives.install:
    - name: link-mongodb-{{ name }}-{{ cmd }}
    - link: {{ dir_symlink }}/{{ cmd }}
    - path: {{ m.pkg.component[name]['path'] }}/{{ cmd }}
    - priority: {{ m.linux.altpriority }}
    - order: 10
    - require:
      - sls: {{ sls_archive_install }}
    - unless:
      - {{ grains.os_family in ('Suse',) }}
      - {{ m.pkg.use_upstream_repo }}

mongodb-archive-alternatives-set-{{ name }}-{{ cmd }}:
  alternatives.set:
    - name: link-mongodb-{{ name }}-{{ cmd }}
    - path: {{ m.pkg.component[name]['path'] }}/{{ cmd }}
    - require:
      - alternatives: mongodb-archive-alternatives-install-{{ name }}-{{ cmd }}
      - sls: {{ sls_archive_install }}
    - unless:
      - {{ grains.os_family in ('Suse',) }}
      - {{ m.pkg.use_upstream_repo }}

                    {%- endfor %}
                {%- endif %}
            {%- endif %}
        {%- endfor %}
    {%- endif %}
{%- endif %}
