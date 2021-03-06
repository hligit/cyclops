package aws

import (
	"fmt"

	"github.com/atlassian-labs/cyclops/pkg/cloudprovider"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ec2"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
)

var log = logf.Log.WithName("aws")

// NewCloudProvider returns a new AWS cloud provider
func NewCloudProvider() (cloudprovider.CloudProvider, error) {
	sess, err := session.NewSession()
	if err != nil {
		return nil, err
	}

	var creds *credentials.Credentials
	config := &aws.Config{Credentials: creds}

	ec2Service := ec2.New(sess, config)
	autoScalingService := autoscaling.New(sess, config)

	p := &provider{
		autoScalingService: autoScalingService,
		ec2Service:         ec2Service,
		logger:             log,
	}

	// Log the provider we used
	credValue, err := autoScalingService.Client.Config.Credentials.Get()
	if err != nil {
		return nil, err
	}
	log.Info(fmt.Sprintf("aws session created successfully, using provider %v", credValue.ProviderName))

	return p, nil
}
