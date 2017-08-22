CloudFormation do

  project_variables = external_parameters.fetch(:project_variables, {})

  ProjectName = project_variables['ProjectName']

  Environment = project_variables['Environment']

  Description "RDS Instances for #{ProjectName} in the #{Environment} environment"

  security_groups = external_parameters.fetch(:securityGroups, [])
  security_groups.each do |name, config|

    Parameter "#{name}SecurityGroupId" do
      Type "String"
      Description "The id of the #{name} security group"
    end

  end

  instances = external_parameters.fetch(:rdsInstances, [])

  instances.each do |instance, config|


    Parameter("#{instance}DBPassword") do
      Description "Database admin account password"
      Type "String"
      AllowedPattern "[a-zA-Z0-9]*"
      NoEcho true
      MaxLength 41
      MinLength 8
      ConstraintDescription "must contain only alphanumeric characters."
    end

    rds_dbs = Hash.new
    rds_dbs['InstanceType'] = config['InstanceType'] || "db.t2.micro"
    rds_dbs['EBS'] = config['EBS'] || 5

    if config['type'].downcase == "mssql"
      rds_dbs['Port'] = config['Port'] || 1433
      rds_dbs['Engine'] = config['Engine'] || "sqlserver-se"
    elsif config['type'].downcase == "oracle"
      rds_dbs['Port'] = config['Port'] || 1521
      rds_dbs['Engine'] = config['Engine'] || "oracle-se1"
    elsif config['type'].downcase == "postgres"
      rds_dbs['Port'] = config['Port'] || 5432
      rds_dbs['Engine'] = config['Engine'] || "postgres"
    end


    RDS_DBInstance instance do
      AllocatedStorage rds_dbs['EBS']
      DBInstanceClass rds_dbs['InstanceType']
      Engine rds_dbs['Engine']
      MasterUsername config['username']
      MasterUserPassword Ref("#{instance}DBPassword")
      Port rds_dbs['Port']
      PubliclyAccessible "false"
      VPCSecurityGroups config['security_groups'].map { |name| Ref("#{name}SecurityGroupId") }
    end

    Output("#{instance}Endpoint") do
      Description "The endpoint of #{instance}"
      Value FnGetAtt(instance, "Endpoint.Address")
    end

    Output("#{instance}Port") do
      Description "The port of #{instance}"
      Value FnGetAtt(instance, "Endpoint.Port")
    end

  end

end
