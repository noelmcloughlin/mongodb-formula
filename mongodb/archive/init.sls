#.-*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- if m.pkg.use_upstream_archive %}

include:
  - .install
  - .alternatives

    {%- endif %}
