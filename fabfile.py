import os.path

from fabric import task


@task
def sync(c):
    """Sync files to host that are required to provision it."""
    with c.cd('/home/vagrant/'):
        c.run('mkdir tmp', warn=True)
        c.put('Makefile', 'tmp')
        c.put('40-vm-on-x220.conf', 'tmp')

@task
def sync_gitconfig(c):
    """Sync gitconfig on host."""
    with c.cd('/home/vagrant/'):
        home_dir = os.path.expanduser('~/.')
        c.put(os.path.join(home_dir, '.gitconfig'))

@task
def make(c, targets):
    """Execute the Makefile on the host with the given targets."""
    targets = targets.replace(',', ' ')
    with c.cd('/home/vagrant/tmp'):
        result = c.run('make {}'.format(targets))
