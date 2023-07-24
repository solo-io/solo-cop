# environment variables
#export MGMT=eks-lab1
#export CLUSTER1=eks-lab1

#for TEST_NAME in all onlyextauth onlywaf nofilters direct; do
for TEST_NAME in nofilters; do
# Execute test 1
kubectl --context ${CLUSTER1} delete configmap k6-test -n k6
sed -i "" "s/exec:.*/exec: '$TEST_NAME'/g" k6-test-single.js
kubectl --context ${CLUSTER1} create configmap k6-test --from-file k6-test.js --from-file k6-test-single.js --from-file k6-test-quick.js  -n k6
kubectl --context ${CLUSTER1} delete -f k6-runner.yaml -n k6
sed -i "" "s/file:.*/file: k6-test-single.js/g" k6-runner.yaml

kubectl --context ${CLUSTER1} apply -f k6-runner.yaml -n k6
date
echo "Waiting for test $TEST_NAME to be finished"
sleep 10
while test $(kubectl --context ${MGMT} -n k6 get po|grep Running|wc -l) -gt "0"; do printf "." && sleep 1; done
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to execute test $TEST_NAME"
done