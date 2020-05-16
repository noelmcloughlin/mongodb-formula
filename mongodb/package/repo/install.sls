# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- if m.pkg.use_upstream_repo and 'repo' in m.pkg %}
        {%- from tplroot ~ "/files/macros.jinja" import format_kwargs with context %}

mongodb-package-repo-install-pkgrepo-managed:
  pkgrepo.managed:
    {{- format_kwargs(m.pkg['repo']) }}

    {%- endif %}
