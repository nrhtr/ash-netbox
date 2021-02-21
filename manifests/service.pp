# @summary Manage the Netbox and Netvox-rq Systemd services
#
# @param install_root
#   The directory where the netbox installation is unpacked
#
# @param user
#   The user running the
#   service.
#
# @param group
#   The group running the
#   service.
#
# A class for running Netbox as a Systemd service
#
class netbox::service (
  Stdlib::Absolutepath $install_root,
  String $user,
  String $group,
){

  $netbox_pid_file = '/var/tmp/netbox.pid'
  $netbox_home     = "${install_root}/netbox"

  # Install netbox unit
  systemd::unit { 'netbox':
    ensure   => 'present',
    type     => 'service',
    settings => {
      'Unit'    =>  {
        'Description'   => 'NetBox WSGI Service',
        'Documentation' => 'https://netbox.readthedocs.io/en/stable/',
        'After'         => 'network-online.target',
        'Wants'         => 'network-online.target',
      },
      'Service' => {
        'Type'             => 'simple',
        'User'             => $user,
        'Group'            => $group,
        'PIDFile'          => $netbox_pid_file,
        'WorkingDirectory' => $netbox_home,
        'ExecStart'        => "${netbox_home}/venv/bin/gunicorn --pid ${netbox_pid_file} --pythonpath ${netbox_home}/netbox --config ${netbox_home}/gunicorn.py netbox.wsgi",
        'Restart'          => 'on-failure',
        'RestartSec'       => '30',
        'PrivateTmp'       => 'true',
      },
      'Install' => {
        'WantedBy' => 'multi-user.target'
      },
    },
  }

  # Install netbox-rq unit
  systemd::unit { 'netbox-rq':
    ensure   => 'present',
    type     => 'service',
    settings => {
      'Unit'    =>  {
        'Description'   => 'NetBox Request Queue Worker',
        'Documentation' => 'https://netbox.readthedocs.io/en/stable/',
        'After'         => 'network-online.target',
        'Wants'         => 'network-online.target',
      },
      'Service' => {
        'Type'             => 'simple',
        'User'             => $user,
        'Group'            => $group,
        'WorkingDirectory' => $netbox_home,
        'ExecStart'        => "${netbox_home}/venv/bin/python3 ${netbox_home}/netbox/manage.py rqworker",
        'Restart'          => 'on-failure',
        'RestartSec'       => '30',
        'PrivateTmp'       => 'true',
      },
      'Install' => {
        'WantedBy' => 'multi-user.target',
      },
    },
  }

  # Manage netbox service
  service { 'netbox':
    ensure => 'running',
    enable => 'true',
  }

  # HACK: does not account for wanting rq/webhooks on older versions
  # 2.6 release makes them mandatory
  if versioncmp($netbox::version, '2.6.0') >= 0 {
    # Manage netbox-rq service
    service { 'netbox-rq':
      ensure => 'running',
      enable => 'true',
    }
  }
}
