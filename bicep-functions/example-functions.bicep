// Example custom Bicep functions for testing

// Function to generate a storage account name with specific prefix and suffix
func generateStorageAccountName(prefix string, suffix string) string => toLower(concat(prefix, uniqueString(resourceGroup().id), suffix))

// Function to calculate subnet CIDR
func getSubnetCidr(vnetCidr string, subnetIndex int) string => cidrSubnet(vnetCidr, 24, subnetIndex)

// Function to create tags object
func createTags(environment string, project string) object => {
  Environment: environment
  Project: project
  ManagedBy: 'Bicep'
}

// Function to validate environment name
func isValidEnvironment(env string) bool => contains(['dev', 'test', 'prod'], env)

// Function to get resource name with convention
func getResourceName(resourceType string, appName string, environment string) string => toLower('${resourceType}-${appName}-${environment}')
