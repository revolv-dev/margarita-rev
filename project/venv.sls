{% import 'project/_vars.sls' as vars with context %}

include:
  - project.dirs
  - project.repo
  - python

venv:
  file.absent:
    - name: {{ vars.venv_dir }}
    - onchanges:
      - pkg: python-pkgs
  virtualenv.managed:
    - name: {{ vars.venv_dir }}
    - python: {{ '/usr/bin/python' ~ pillar['python_version'] }}
    - user: {{ pillar['project_name'] }}
    - require:
      - pip: virtualenv
      - file: root_dir
      - file: project_repo
      - file: venv
      - pkg: python-pkgs

pip_requirements:
  pip.installed:
    - bin_env: {{ vars.venv_dir }}
{% if grains['environment'] == 'local' %}
    - requirements: {{ vars.build_path(vars.source_dir, pillar.get('requirements_file', 'requirements/dev.txt')) }}
{% else %}
    - requirements: {{ vars.build_path(vars.source_dir, pillar.get('requirements_file', 'requirements/production.txt')) }}
{% endif %}
    - upgrade: true
    - require:
      - virtualenv: venv

{% if vars.use_newrelic %}
# Make sure the New Relic agent is installed in the virtual env.
# This allows us to add New Relic without modifying the project files.
newrelic_agent:
  pip.installed:
    - name: "newrelic"
    - bin_env: {{ vars.venv_dir }}
    - upgrade: true
    - require:
      - virtualenv: venv
{% endif %}

project_path:
  file.managed:
    - contents: "{{ vars.source_dir }}"
    - name: {{ vars.build_path(vars.venv_dir, 'lib/python' ~ pillar['python_version'] ~ '/site-packages/project.pth') }}
    - user: {{ pillar['project_name'] }}
    - group: {{ pillar['project_name'] }}
    - require:
      - pip: pip_requirements
{% if vars.use_newrelic %}
      - pip: newrelic_agent
{% endif %}

ghostscript:
  pkg.installed
