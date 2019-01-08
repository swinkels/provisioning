from fabric import task

@task
def copy_files(c):
    with c.cd('/home/vagrant/'):
        c.run('mkdir tmp', warn=True)
        c.put('Makefile', 'tmp')
        c.put('40-vm-on-x220.conf', 'tmp')

@task
def x220_add_fullscreen_to_vm(c):
    with c.cd('/home/vagrant/tmp'):
        c.run('make x220-add-fullscreen-to-vm')
