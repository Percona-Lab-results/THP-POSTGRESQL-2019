#!/bin/bash
if [ "$#" -ne 2 ];
then
   echo "Usage: pgbench.sh db dir"
   exit $?
fi

echo "Bash version ${BASH_VERSION}"
echo `postgres --version`
echo "Starting PostgreSQL"
pg_ctl start
psql postgres -c 'show shared_buffers' >> $2/tps
psql postgres -c 'show work_mem' >> $2/tps
psql postgres -c 'show random_page_cost' >> $2/tps
psql postgres -c 'show maintenance_work_mem'>> $2/tps
psql postgres -c 'show synchronous_commit'>> $2/tps
psql postgres -c 'show seq_page_cost' >> $2/tps
psql postgres -c 'show max_wal_size'>> $2/tps
psql postgres -c 'show checkpoint_timeout'>> $2/tps
psql postgres -c 'show synchronous_commit'>> $2/tps
psql postgres -c 'show checkpoint_completion_target'>> $2/tps
psql postgres -c 'show autovacuum_vacuum_scale_factor'>> $2/tps
psql postgres -c 'show effective_cache_size'>> $2/tps
psql postgres -c 'show min_wal_size'>> $2/tps
psql postgres -c 'show wal_compression'>> $2/tps
rm smblad*


for s in 10 20
do  
  dropdb $1
  createdb $1
  ./tpcc.lua --pgsql-user=ibrar --pgsql-db=$1 --time=600  --report-interval=1 --tables=$s --scale=48 --use_fk=0  --trx_level=RC --pgsql-password=test --db-driver=pgsql prepare
  for c in 64 128 256
  do  	
    for i in {1..3}
    do
        psql $1 -c CHECKPOINT
        psql $1 -c 'vacuum'
        nmon -f 
        (sudo -s perf stat -e dTLB-loads,dTLB-load-misses,iTLB-loads,iTLB-load-misses ./tpcc.lua --pgsql-user=ibrar --pgsql-db=$1 --time=600 --threads=$c --report-interval=1 --tables=$s --scale=48 --use_fk=0  --trx_level=RC --pgsql-password='' --db-driver=pgsql run) &>>$2/tps-$c 
        pkill nmon
        mv smblad* $2/$s-$i-$c.nmon 
    done
	done
done

echo "Stopping PostgreSQL"

psql $1 -c CHECKPOINT
pg_ctl stop
