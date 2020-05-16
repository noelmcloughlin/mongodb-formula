# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- for name in m.wanted.gui %}
        {%- if 'macapp' in m.pkg.gui[name] and m.pkg.gui[name]['macapp'] %}

mongodb-gui-{{ name }}-macapp-clean-files:
  file.absent:
    - names:
      - {{ m.dir.tmp }}
      - {{ m.dir.macapp }}/{{ m.pkg.gui[name]['name'] }}.app
            {%- if 'commands' in m.pkg.gui[name] and m.pkg.gui[name]['commands'] is iterable %}
                {%- for cmd in gui.['commands'] %}
      - {{ m.dir.symlink }}/bin/{{ cmd }}
                {%- endfor %}
            {%- endif %}

    {%- else %}

mongodb-gui-{{ name }}-macapp-clean-unavailable:
  test.show_notification:
    - text: |
        The mongodb macpackage is only available on MacOS

    {%- endif %}
