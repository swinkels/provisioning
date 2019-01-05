from fabric import task

@task
def copy_makefile(c):
    with c.cd('/home/vagrant/'):
        c.run('mkdir tmp', warn=True)
        c.put('Makefile', 'tmp')
