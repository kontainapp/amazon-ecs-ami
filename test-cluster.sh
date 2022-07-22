#!/bin/sh
#set -x

region=us-west-1
ami_id=''

for arg in "$@"
do
   case "$arg" in
      --region=*)
        region="${1#*=}"
        ;;
      --ami=*)
        ami_id="${1#*=}"
    esac
    shift
done

[[ -z $ami_id ]] && echo "ami is required" && exit 1
echo $region 
echo $ami_id


readonly security_group_name=http_tests
readonly cluster_name=kontain-ecs-cluster
readonly task_family=kontain-ecs-test

# echo get AMI Id
# AMI=$(aws --region ${region} ec2 describe-images --owners self --filters "Name=name,Values=${ami_name}" | jq -r '.Images | .[0] |.ImageId')
# echo AMI = ${AMI}

echo get VPC ID 
VPC_ID=$(aws  --region ${region} ec2  describe-vpcs | jq -r '.Vpcs | .[0] | .VpcId')
echo VPC_ID = ${VPC_ID}

echo creating security group
SECURITY_GROUP_ID=$(aws  --region ${region} ec2 create-security-group --group-name $security_group_name --description "ECS_TEST_SG" --vpc-id ${VPC_ID} | jq -r '.GroupId')
echo SECURITY_GROUP_ID = ${SECURITY_GROUP_ID}

echo wait for security group to be created 
aws  --region ${region} ec2  wait security-group-exists --group-ids ${SECURITY_GROUP_ID} > /dev/null

echo allow ssh connection
aws  --region ${region} ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 > /dev/null
echo allow http connection
aws  --region ${region} ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 > /dev/null

echo creating confuration files
cat << EOF > instance_user_data.txt
#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
EOF

cat <<EOF > task_def.json
{
    "family": "$task_family",
    "executionRoleArn": "arn:aws:iam::782340374253:role/ecsTaskExecutionRole",
    "networkMode": "bridge",
    "memory": "512",
    "containerDefinitions": [
        {
            "name": "dweb",
            "image": "kontainapp/runenv-dweb",
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "./dweb",
                "80"
            ],
            "interactive": true,
            "pseudoTerminal": true
        }
    ],
    "requiresCompatibilities": [
        "EC2"
    ],
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    }
}
EOF

echo creating cluster
aws --region ${region}  ecs create-cluster --cluster-name ${cluster_name} > /dev/null

echo launching an Instance with the Amazon ECS AMI
INSTANCE_ID=$(aws --region ${region} ec2 run-instances --image-id ${ami_id} --count 1 \
    --instance-type t2.micro --key-name ezleka --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=KONTAIN_ECS-TEST}]' \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --iam-instance-profile Name=ecsInstanceRoleEC2 \
    --user-data file://instance_user_data.txt  |jq -r '.Instances | .[0] | .InstanceId')
echo INSTANCE_ID = ${INSTANCE_ID}

echo waiting for instance to reach runnign state 
aws --region ${region} ec2 wait instance-running --instance-ids ${INSTANCE_ID} > /dev/null

echo getting instance public IP
INSTANCE_PUBLIC_IP=$(aws --region ${region} ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
    "Name=instance-id,Values=${INSTANCE_ID}" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text)
echo INSTANCE_PUBLIC_IP = ${INSTANCE_PUBLIC_IP}

echo wait for instance to connect to clucter
INSTANCE_COUNT=0
while [ ${INSTANCE_COUNT} -eq 0 ]
do
    INSTANCE_COUNT=$(aws --region ${region} ecs list-container-instances --cluster $cluster_name | jq -r '.containerInstanceArns | length')
    echo -n .
done

echo registering task definition
TASK_REVISION=$(aws --region ${region} ecs register-task-definition --cli-input-json file://task_def.json | jq -r '.taskDefinition | .revision')
echo TASK_REVISION = ${TASK_REVISION}

echo run task
TASK_ARN=$(aws --region ${region} ecs run-task --count 1 --cluster $cluster_name --task-definition $task_family | jq -r '.tasks | .[0] | .taskArn')
echo TASK_ARN = ${TASK_ARN}
echo wait for task to be running
aws --region ${region} ecs wait tasks-running  --cluster $cluster_name --tasks ${TASK_ARN} > /dev/null

echo get page 
ERROR_CODE=0
PAGE=$(curl --data x= http://${INSTANCE_PUBLIC_IP} | grep "kontain.KKM")
echo ${PAGE}
if [ -z ${PAGE} ]; then
    echo Error: DWEB did not return expected page
    ERROR_CODE=1
else
    echo ${PAGE}
fi;

echo cleaning everything up
aws --region ${region} ec2 terminate-instances --instance-ids ${INSTANCE_ID} > /dev/null
aws --region ${region} ec2 wait instance-terminated --instance-ids ${INSTANCE_ID} > /dev/null
aws --region ${region} ec2 delete-security-group --group-id ${SECURITY_GROUP_ID} > /dev/null
aws --region ${region} ecs deregister-task-definition --task-definition ${task_family}:${TASK_REVISION} > /dev/null
aws --region ${region} ecs delete-cluster --cluster ${cluster_name} > /dev/null

exit ${ERROR_CODE}