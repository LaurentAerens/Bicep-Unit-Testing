// Example custom Bicep functions for testing

// Function to create a standardized resource name
func getResourceName(resourceType string, appName string, environment string) string => toLower('${resourceType}-${appName}-${environment}')

// Function to create tags object
func createTags(environment string, project string) object => {
  Environment: environment
  Project: project
  ManagedBy: 'Bicep'
}

// Function to validate environment name
func isValidEnvironment(env string) bool => contains(['dev', 'test', 'prod'], env)

// Function to generate a suffix based on length limit
func getTruncatedName(name string, maxLength int) string => length(name) > maxLength ? substring(name, 0, maxLength) : name

// Function to check if a string is empty or whitespace
func isEmptyOrWhitespace(str string) bool => length(trim(str)) == 0
