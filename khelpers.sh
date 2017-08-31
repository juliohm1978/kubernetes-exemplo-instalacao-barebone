cat <<EOF > /usr/local/bin/kshell
#!/bin/sh
if [ "$1" = "" ]; then
  echo "Usage: kshell <pod>"
  exit 1
fi
COLUMNS=`tput cols`
LINES=`tput lines`
TERM=xterm
kubectl exec -i -t $1 env COLUMNS=$COLUMNS LINES=$LINES TERM=$TERM bash
EOF
chmod +x /usr/local/bin/kshell

cat <<EOF > /usr/local/bin/k
#!/bin/bash
kubectl \$@
EOF
chmod +x /usr/local/bin/k

cat <<EOF > /usr/local/bin/kpods
#!/bin/bash
kubectl get pods \$@
EOF
chmod +x /usr/local/bin/kpods

cat <<EOF > /usr/local/bin/kpodnames
#!/bin/bash
kubectl get pods $@ | awk '{print $1}' | grep -v "NAME"
EOF
chmod +x /usr/local/bin/kpodnames


cat <<EOF > /usr/local/bin/kallpods
#!/bin/bash
kubectl get pods --all-namespaces \$@
EOF
chmod +x /usr/local/bin/kallpods

cat <<EOF > /usr/local/bin/kallsvc
#!/bin/bash
kubectl get svc --all-namespaces \$@
EOF
chmod +x /usr/local/bin/kallsvc

cat <<EOF > /usr/local/bin/kalling
#!/bin/bash
kubectl get ing --all-namespaces \$@
EOF
chmod +x /usr/local/bin/kalling

cat <<EOF > /usr/local/bin/kalldepls
#!/bin/bash
kubectl get deployments --all-namespaces \$@
EOF
chmod +x /usr/local/bin/kalldepls

cat <<EOF > /usr/local/bin/kallpvc
#!/bin/bash
kubectl get pvc --all-namespaces \$@
EOF
chmod +x /usr/local/bin/kallpvc

cat <<EOF > /usr/local/bin/knodes
#!/bin/bash
kubectl get nodes \$@
EOF
chmod +x /usr/local/bin/knodes

cat <<EOF > /usr/local/bin/kapply
#!/bin/bash
kubectl apply \$@
EOF
chmod +x /usr/local/bin/kapply

cat <<EOF > /usr/local/bin/d
#!/bin/bash
docker \$@
EOF
chmod +x /usr/local/bin/d
