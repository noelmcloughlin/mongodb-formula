# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import data as d with context %}
{%- set formula = d.formula %}

    {%- for comp in d.software_component_matrix %}
        {%- if comp in d.wanted and d.wanted is iterable and comp in d.pkg and d.pkg[comp] is mapping %}
            {%- for name,v in d.pkg[comp].items() %}
                {%- if name in d.wanted[comp] %}
                    {%- set software = d.pkg[comp][name] %}
                    {%- if 'user' in software and 'service' in software and software['service'] is mapping %}
                        {%- set servicename = software['service']['get'](name, {}).get('name', name) %}

{{ formula }}-config-usergroup-{{ servicename }}-install-usergroup-present:
  group.present:
    - name: {{ software['group'] }}
    - require_in:
      - user: {{ formula }}-config-usergroup-{{ servicename }}-install-usergroup-present
  user.present:
    - name: {{ software['user'] }}
    - shell: /bin/false
    - createhome: false
    - groups:
      - {{ software['user'] }}
                        {%- if grains.os_family == 'MacOS' %}
    - unless: /usr/bin/dscl . list /Users | grep {{ software['user'] }} >/dev/null 2>&1
                        {%- endif %}  {# darwin #}

                    {%- endif %}      {# service-users #}
                {%- endif %}          {# wanted #}
            {%- endfor %}             {# component #}
        {%- endif %}                  {# wanted #}
    {%- endfor %}                     {# components #}
