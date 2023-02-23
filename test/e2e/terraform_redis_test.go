package e2e

import (	
	"regexp"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExamplesMain(t *testing.T) {		
	var vars map[string]interface{}	
	test_helper.RunE2ETest(t, "../../", "examples/main", terraform.Options{
		Upgrade: false,	
		Vars:    vars,	
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		redisId, ok := output["test_redis_id"].(string)
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Cache/Redis/.+"), redisId)
		assertOutputNotEmpty(t, output, "test_redis_name")
		assertOutputNotEmpty(t, output, "test_redis_hostname")
	})
}

func assertOutputNotEmpty(t *testing.T, output test_helper.TerraformOutput, name string) {
	o, ok := output[name].(string)
	assert.True(t, ok)
	assert.NotEqual(t, "", o)
}