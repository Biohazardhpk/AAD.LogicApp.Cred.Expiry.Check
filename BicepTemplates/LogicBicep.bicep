param workflows_AD_Check string
param keyVaultConn string
param keyVaultConn_id string
param o365Conn string
param o365Conn_id string
param subscriptionId string = subscription().subscriptionId
param logicResourceGroup string = resourceGroup().name
param connections_keyvault_externalid string = '/subscriptions/${subscriptionId}/resourceGroups/${logicResourceGroup}/providers/Microsoft.Web/connections/${keyVaultConn}'
param connections_office365_externalid string = '/subscriptions/${subscriptionId}/resourceGroups/${logicResourceGroup}/providers/Microsoft.Web/connections/${o365Conn}'
param email string
param FutureTime int

resource workflows_AD_Check_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflows_AD_Check
  location: 'northeurope'
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Day'
            interval: 1
          }
          evaluatedRecurrence: {
            frequency: 'Day'
            interval: 1
          }
          type: 'Recurrence'
        }
      }

      actions: {
        'AADAppSecretsnCertsExpirationNotification-Client-id': {
          runAfter: {
            'AADAppSecretsnCertsExpirationNotification-Tenant-id': [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'AADAppSecretsnCertsExpirationNotification-Client-id\')}/value'
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'inputs'
                'outputs'
              ]
            }
          }
        }
        'AADAppSecretsnCertsExpirationNotification-Client-secret': {
          runAfter: {
            'AADAppSecretsnCertsExpirationNotification-Client-id': [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'AADAppSecretsnCertsExpirationNotification-Client-secret\')}/value'
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'inputs'
                'outputs'
              ]
            }
          }
        }
        Close_HTML_tags: {
          runAfter: {
            Until: [
              'Succeeded'
            ]
          }
          type: 'AppendToStringVariable'
          inputs: {
            name: 'html'
            value: '<tbody></table>'
          }
        }
        Get_Auth_Token: {
          runAfter: {
            Initialize_daysTilExpiration: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            body: 'grant_type=client_credentials\n&client_id=@{body(\'AADAppSecretsnCertsExpirationNotification-Client-id\')?[\'value\']}\n&client_secret=@{body(\'AADAppSecretsnCertsExpirationNotification-Client-secret\')?[\'value\']}\n&scope=https://graph.microsoft.com/.default'
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded'
            }
            method: 'POST'
            uri: 'https://login.microsoftonline.com/@{body(\'AADAppSecretsnCertsExpirationNotification-Tenant-id\')?[\'value\']}/oauth2/v2.0/token'
          }
        }
        'Initialize_-_NextLink': {
          runAfter: {
            'Parse_JSON_-_Retrieve_token_Info': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'NextLink'
                type: 'string'
                value: 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials&$top=999'
              }
            ]
          }
        }
        'Initialize_-_keyCredential': {
          runAfter: {
            Initialize_passwordCredential: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'keyCredential'
                type: 'array'
              }
            ]
          }
        }
        Initialize_appid: {
          runAfter: {
            'AADAppSecretsnCertsExpirationNotification-Client-secret': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'AppID'
                type: 'string'
                value: ''
              }
            ]
          }
        }
        Initialize_daysTilExpiration: {
          runAfter: {
            Initialize_html: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'daysTilExpiration'
                type: 'float'
                value: 10
              }
            ]
          }
        }
        Initialize_displayName: {
          runAfter: {
            Initialize_appid: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'displayName'
                type: 'string'
                value: ''
              }
            ]
          }
        }
        Initialize_html: {
          runAfter: {
            Initialize_styles: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'html'
                type: 'string'
                value: '<table  @{variables(\'styles\').tableStyle}><thead><th  @{variables(\'styles\').headerStyle}>Application ID</th><th  @{variables(\'styles\').headerStyle}>Display Name</th><th @{variables(\'styles\').headerStyle}> Key Id</th><th  @{variables(\'styles\').headerStyle}>Days until Expiration</th><th  @{variables(\'styles\').headerStyle}>Type</th><th  @{variables(\'styles\').headerStyle}>Expiration Date</th><th @{variables(\'styles\').headerStyle}>Owner</th></thead><tbody>'
              }
            ]
          }
        }
        Initialize_passwordCredential: {
          runAfter: {
            Initialize_displayName: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'passwordCredential'
                type: 'array'
              }
            ]
          }
        }
        Initialize_styles: {
          runAfter: {
            'Initialize_-_keyCredential': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'styles'
                type: 'object'
                value: {
                  cellStyle: 'style="font-family: Calibri; padding: 5px; border: 1px solid black;"'
                  headerStyle: 'style="font-family: Helvetica; padding: 5px; border: 1px solid black;"'
                  redStyle: 'style="background-color:red; font-family: Calibri; padding: 5px; border: 1px solid black;"'
                  tableStyle: 'style="border-collapse: collapse;"'
                  yellowStyle: 'style="background-color:yellow; font-family: Calibri; padding: 5px; border: 1px solid black;"'
                }
              }
            ]
          }
        }
        'Parse_JSON_-_Retrieve_token_Info': {
          runAfter: {
            Get_Auth_Token: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_Auth_Token\')'
            schema: {
              properties: {
                access_token: {
                  type: 'string'
                }
                expires_in: {
                  type: 'integer'
                }
                ext_expires_in: {
                  type: 'integer'
                }
                token_type: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'inputs'
              ]
            }
          }
        }
        Send_the_list_of_applications: {
          runAfter: {
            Close_HTML_tags: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              Body: '<p>@{variables(\'html\')}</p>'
              Subject: 'List of Secrets and Certificates near expiration'
              To: email
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'inputs'
                'outputs'
              ]
            }
          }
        }
        'AADAppSecretsnCertsExpirationNotification-Tenant-id': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'AADAppSecretsnCertsExpirationNotification-Tenant-id\')}/value'
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'inputs'
                'outputs'
              ]
            }
          }
        }
        Until: {
          actions: {
            'Foreach_-_apps': {
              foreach: '@body(\'Parse_JSON\')?[\'value\']'
              actions: {
                'For_each_-_PasswordCred': {
                  foreach: '@items(\'Foreach_-_apps\')?[\'passwordCredentials\']'
                  actions: {
                    Condition: {
                      actions: {
                        DifferentAsDays: {
                          runAfter: {
                            StartTimeTickValue: [
                              'Succeeded'
                            ]
                          }
                          type: 'Compose'
                          inputs: '@div(div(div(mul(sub(outputs(\'EndTimeTickValue\'),outputs(\'StartTimeTickValue\')),100),1000000000) , 3600), 24)'
                        }
                        EndTimeTickValue: {
                          runAfter: {}
                          type: 'Compose'
                          inputs: '@ticks(item()?[\'endDateTime\'])'
                        }
                        Get_Secret_Owner: {
                          runAfter: {
                            Set_variable: [
                              'Succeeded'
                            ]
                          }
                          type: 'Http'
                          inputs: {
                            headers: {
                              Authorization: 'Bearer @{body(\'Parse_JSON_-_Retrieve_token_Info\')?[\'access_token\']}'
                            }
                            method: 'GET'
                            uri: 'https://graph.microsoft.com/v1.0/applications/@{items(\'Foreach_-_apps\')?[\'id\']}/owners'
                          }
                        }
                        In_Case_of_No_Owner: {
                          actions: {
                            Append_to_string_variable_4: {
                              runAfter: {}
                              type: 'AppendToStringVariable'
                              inputs: {
                                name: 'html'
                                value: '<tr><td @{variables(\'styles\').cellStyle}><a href="https://ms.portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/@{variables(\'appId\')}/isMSAApp/">@{variables(\'appId\')}</a></td><td @{variables(\'styles\').cellStyle}>@{variables(\'displayName\')}</td><td @{variables(\'styles\').cellStyle}>@{items(\'For_each_-_PasswordCred\')?[\'keyId\']}</td><td @{if(less(variables(\'daystilexpiration\'),100),variables(\'styles\').redStyle,if(less(variables(\'daystilexpiration\'),150),variables(\'styles\').yellowStyle,variables(\'styles\').cellStyle))}>@{variables(\'daystilexpiration\')} </td><td @{variables(\'styles\').cellStyle}>Secret</td><td @{variables(\'styles\').cellStyle}>@{formatDateTime(item()?[\'endDateTime\'],\'g\')}</td><td @{variables(\'styles\').cellStyle}>No Owner</td></tr>'
                              }
                            }
                          }
                          runAfter: {
                            Get_Secret_Owner: [
                              'Succeeded'
                            ]
                          }
                          else: {
                            actions: {
                              Append_to_string_variable: {
                                runAfter: {}
                                type: 'AppendToStringVariable'
                                inputs: {
                                  name: 'html'
                                  value: '<tr><td @{variables(\'styles\').cellStyle}><a href="https://ms.portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/@{variables(\'appId\')}/isMSAApp/">@{variables(\'appId\')}</a></td><td @{variables(\'styles\').cellStyle}>@{variables(\'displayName\')}</td><td @{variables(\'styles\').cellStyle}>@{items(\'For_each_-_PasswordCred\')?[\'keyId\']}</td><td @{if(less(variables(\'daystilexpiration\'),100),variables(\'styles\').redStyle,if(less(variables(\'daystilexpiration\'),150),variables(\'styles\').yellowStyle,variables(\'styles\').cellStyle))}>@{variables(\'daystilexpiration\')} </td><td @{variables(\'styles\').cellStyle}>Secret</td><td @{variables(\'styles\').cellStyle}>@{formatDateTime(item()?[\'endDateTime\'],\'g\')}</td><td @{variables(\'styles\').cellStyle}><a href="mailto:@{body(\'Get_Secret_Owner\')?[\'value\'][0]?[\'userPrincipalName\']}">@{body(\'Get_Secret_Owner\')?[\'value\'][0]?[\'givenName\']} @{body(\'Get_Secret_Owner\')?[\'value\'][0]?[\'surname\']}</a></td></tr>'
                                }
                              }
                              Condition_3: {
                                actions: {
                                  Compose_2: {
                                    runAfter: {}
                                    type: 'Compose'
                                    inputs: 'Hello @{body(\'Get_Secret_Owner\')?[\'value\'][0]?[\'givenName\']},<br/>\nYou are owner of the application <strong>@{items(\'Foreach_-_apps\')?[\'displayName\']}</strong>.<br/>\n\nOne of the secrets of this application is going to expire in @{variables(\'daysTilExpiration\')} days.<br/>\n\nPlease take action to avoid any authentication issues related to the expiration of the secret.<br/><br/>\n\nHere are the details of the secret :<br/>\n<strong>Secret Id :</strong> @{items(\'For_each_-_PasswordCred\')?[\'keyId\']}<br/>\n<strong>Expiration time :</strong> @{formatDateTime(items(\'For_each_-_PasswordCred\')?[\'endDateTime\'],\'g\')}<br/>\n<strong>App Id :</strong> <a href="https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/@{items(\'Foreach_-_apps\')?[\'appId\']}/isMSAApp/" >@{items(\'Foreach_-_apps\')?[\'appId\']}</a><br/><br/>\n\n\nThank you'
                                  }
                                  'Send_an_email_(V2)_2': {
                                    runAfter: {
                                      Compose_2: [
                                        'Succeeded'
                                      ]
                                    }
                                    type: 'ApiConnection'
                                    inputs: {
                                      body: {
                                        Body: '<p>@{outputs(\'Compose_2\')}</p>'
                                        Importance: 'Normal'
                                        Subject: 'Secrets are going to expire soon | @{items(\'Foreach_-_apps\')?[\'displayName\']}'
                                        To: '@{body(\'Get_Secret_Owner\')?[\'value\'][0]?[\'mail\']}'
                                      }
                                      host: {
                                        connection: {
                                          name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
                                        }
                                      }
                                      method: 'post'
                                      path: '/v2/Mail'
                                    }
                                  }
                                }
                                runAfter: {
                                  Append_to_string_variable: [
                                    'Succeeded'
                                  ]
                                }
                                expression: {
                                  and: [
                                    {
                                      less: [
                                        '@variables(\'daysTilExpiration\')'
                                        '@float(\'15\')'
                                      ]
                                    }
                                  ]
                                }
                                type: 'If'
                              }
                            }
                          }
                          expression: {
                            and: [
                              {
                                equals: [
                                  '@length(body(\'Get_Secret_Owner\')?[\'value\'])'
                                  '@int(\'0\')'
                                ]
                              }
                            ]
                          }
                          type: 'If'
                        }
                        Set_variable: {
                          runAfter: {
                            DifferentAsDays: [
                              'Succeeded'
                            ]
                          }
                          type: 'SetVariable'
                          inputs: {
                            name: 'daysTilExpiration'
                            value: '@outputs(\'DifferentAsDays\')'
                          }
                        }
                        StartTimeTickValue: {
                          runAfter: {
                            EndTimeTickValue: [
                              'Succeeded'
                            ]
                          }
                          type: 'Compose'
                          inputs: '@ticks(utcnow())'
                        }
                      }
                      runAfter: {}
                      expression: {
                        and: [
                          {
                            greaterOrEquals: [
                              '@body(\'Get_future_time\')'
                              '@items(\'For_each_-_PasswordCred\')?[\'endDateTime\']'
                            ]
                          }
                        ]
                      }
                      type: 'If'
                    }
                  }
                  runAfter: {
                    'Set_variable_-_keyCredential': [
                      'Succeeded'
                    ]
                  }
                  type: 'Foreach'
                }
                For_each_KeyCred: {
                  foreach: '@items(\'Foreach_-_apps\')?[\'keyCredentials\']'
                  actions: {
                    Condition_2: {
                      actions: {
                        Condition_5: {
                          actions: {
                            Append_Certificate_to_HTML_without_owner: {
                              runAfter: {}
                              type: 'AppendToStringVariable'
                              inputs: {
                                name: 'html'
                                value: '<tr><td @{variables(\'styles\').cellStyle}><a href="https://ms.portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/@{variables(\'appId\')}/isMSAApp/">@{variables(\'appId\')}</a></td><td @{variables(\'styles\').cellStyle}>@{variables(\'displayName\')}</td><td @{variables(\'styles\').cellStyle}>@{items(\'For_each_KeyCred\')?[\'keyId\']}</td><td @{if(less(variables(\'daystilexpiration\'), 15), variables(\'styles\').redStyle, if(less(variables(\'daystilexpiration\'), 30), variables(\'styles\').yellowStyle, variables(\'styles\').cellStyle))}>@{variables(\'daystilexpiration\')} </td><td @{variables(\'styles\').cellStyle}>Certificate</td><td @{variables(\'styles\').cellStyle}>@{formatDateTime(item()?[\'endDateTime\'], \'g\')}</td><td @{variables(\'styles\').cellStyle}>No Owner</td></tr>'
                              }
                            }
                          }
                          runAfter: {
                            Get_Certificate_Owner: [
                              'Succeeded'
                            ]
                          }
                          else: {
                            actions: {
                              Append_Certificate_to_HTML_with_owner: {
                                runAfter: {}
                                type: 'AppendToStringVariable'
                                inputs: {
                                  name: 'html'
                                  value: '<tr><td @{variables(\'styles\').cellStyle}><a href="https://ms.portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/@{variables(\'appId\')}/isMSAApp/">@{variables(\'appId\')}</a></td><td @{variables(\'styles\').cellStyle}>@{variables(\'displayName\')}</td><td @{variables(\'styles\').cellStyle}>@{items(\'For_each_KeyCred\')?[\'keyId\']}</td><td @{if(less(variables(\'daystilexpiration\'), 15), variables(\'styles\').redStyle, if(less(variables(\'daystilexpiration\'), 30), variables(\'styles\').yellowStyle, variables(\'styles\').cellStyle))}>@{variables(\'daystilexpiration\')} </td><td @{variables(\'styles\').cellStyle}>Certificate</td><td @{variables(\'styles\').cellStyle}>@{formatDateTime(item()?[\'endDateTime\'], \'g\')}</td><td @{variables(\'styles\').cellStyle}><a href="mailto:@{body(\'Get_Certificate_Owner\')?[\'value\'][0]?[\'userPrincipalName\']}">@{body(\'Get_Certificate_Owner\')?[\'value\'][0]?[\'givenName\']} @{body(\'Get_Certificate_Owner\')?[\'value\'][0]?[\'surname\']}</a></td></tr>'
                                }
                              }
                              Condition_4: {
                                actions: {
                                  'Prepare_HTML_for_owner_-_Certificate': {
                                    runAfter: {}
                                    type: 'Compose'
                                    inputs: 'Hi @{body(\'Get_Certificate_Owner\')?[\'value\'][0]?[\'givenName\']},<br/>\nWe want to update you that, you are owner of the application <strong>@{items(\'Foreach_-_apps\')?[\'displayName\']}</strong><br/>\n\nOne of the secrets of this applicatin is going to expire in @{variables(\'daysTilExpiration\')} days.<br/>\n\nPlease take an action to avoid any authentication issues related to this secret.\n<br/><br/>\nHere are the details of the Certificate :<br/>\n<strong>Certificate Id :</strong> @{items(\'For_each_KeyCred\')?[\'keyId\']}<br/>\n<strong>Expiration time :</strong> @{formatDateTime(items(\'For_each_KeyCred\')?[\'endDateTime\'], \'g\')}<br/>\n<strong>App Id :</strong> <a href="https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/@{items(\'Foreach_-_apps\')?[\'appId\']}/isMSAApp/>@{items(\'Foreach_-_apps\')?[\'appId\']}</a><br/><br/>\n\n\nThank you'
                                  }
                                  'Send_an_email_(V2)_3': {
                                    runAfter: {
                                      'Prepare_HTML_for_owner_-_Certificate': [
                                        'Succeeded'
                                      ]
                                    }
                                    type: 'ApiConnection'
                                    inputs: {
                                      body: {
                                        Body: '<p>@{outputs(\'Prepare_HTML_for_owner_-_Certificate\')}</p>'
                                        Importance: 'Normal'
                                        Subject: ' secrets are going to expire soon | @{items(\'Foreach_-_apps\')?[\'displayName\']}'
                                        To: '@{body(\'Get_Certificate_Owner\')?[\'value\'][0]?[\'mail\']}'
                                      }
                                      host: {
                                        connection: {
                                          name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
                                        }
                                      }
                                      method: 'post'
                                      path: '/v2/Mail'
                                    }
                                  }
                                }
                                runAfter: {
                                  Append_Certificate_to_HTML_with_owner: [
                                    'Succeeded'
                                  ]
                                }
                                expression: {
                                  and: [
                                    {
                                      less: [
                                        '@variables(\'daysTilExpiration\')'
                                        '@float(\'15\')'
                                      ]
                                    }
                                  ]
                                }
                                type: 'If'
                              }
                            }
                          }
                          expression: {
                            and: [
                              {
                                equals: [
                                  '@length(body(\'Get_Certificate_Owner\')?[\'value\'])'
                                  '@int(\'0\')'
                                ]
                              }
                            ]
                          }
                          type: 'If'
                        }
                        DifferentAsDays2: {
                          runAfter: {
                            StartTimeTickValue2: [
                              'Succeeded'
                            ]
                          }
                          type: 'Compose'
                          inputs: '@div(div(div(mul(sub(outputs(\'EndTimeTickValue2\'),outputs(\'StartTimeTickValue2\')),100),1000000000) , 3600), 24)'
                        }
                        EndTimeTickValue2: {
                          runAfter: {}
                          type: 'Compose'
                          inputs: '@ticks(item()?[\'endDateTime\'])'
                        }
                        Get_Certificate_Owner: {
                          runAfter: {
                            Store_Days_till_expiration: [
                              'Succeeded'
                            ]
                          }
                          type: 'Http'
                          inputs: {
                            headers: {
                              Authorization: 'Bearer @{body(\'Parse_JSON_-_Retrieve_token_Info\')?[\'access_token\']}'
                            }
                            method: 'GET'
                            uri: 'https://graph.microsoft.com/v1.0/applications/@{items(\'Foreach_-_apps\')?[\'id\']}/owners'
                          }
                        }
                        StartTimeTickValue2: {
                          runAfter: {
                            EndTimeTickValue2: [
                              'Succeeded'
                            ]
                          }
                          type: 'Compose'
                          inputs: '@ticks(utcnow())'
                        }
                        Store_Days_till_expiration: {
                          runAfter: {
                            DifferentAsDays2: [
                              'Succeeded'
                            ]
                          }
                          type: 'SetVariable'
                          inputs: {
                            name: 'daysTilExpiration'
                            value: '@outputs(\'DifferentAsDays2\')'
                          }
                        }
                      }
                      runAfter: {}
                      expression: {
                        and: [
                          {
                            greaterOrEquals: [
                              '@body(\'Get_future_time\')'
                              '@items(\'For_each_KeyCred\')?[\'endDateTime\']'
                            ]
                          }
                        ]
                      }
                      type: 'If'
                    }
                  }
                  runAfter: {
                    'For_each_-_PasswordCred': [
                      'Succeeded'
                    ]
                  }
                  type: 'Foreach'
                }
                'Set_variable_-_appId': {
                  runAfter: {}
                  type: 'SetVariable'
                  inputs: {
                    name: 'AppID'
                    value: '@items(\'Foreach_-_apps\')?[\'appId\']'
                  }
                }
                'Set_variable_-_displayName': {
                  runAfter: {
                    'Set_variable_-_appId': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'displayName'
                    value: '@items(\'Foreach_-_apps\')?[\'displayName\']'
                  }
                }
                'Set_variable_-_keyCredential': {
                  runAfter: {
                    'Set_variable_-_passwordCredential': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'keyCredential'
                    value: '@items(\'Foreach_-_apps\')?[\'keyCredentials\']'
                  }
                }
                'Set_variable_-_passwordCredential': {
                  runAfter: {
                    'Set_variable_-_displayName': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'passwordCredential'
                    value: '@items(\'Foreach_-_apps\')?[\'passwordCredentials\']'
                  }
                }
              }
              runAfter: {
                Get_future_time: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
              runtimeConfiguration: {
                concurrency: {
                  repetitions: 1
                }
              }
            }
            Get_future_time: {
              runAfter: {
                Parse_JSON: [
                  'Succeeded'
                ]
              }
              type: 'Expression'
              kind: 'GetFutureTime'
              inputs: {
                interval: FutureTime
                timeUnit: 'Day'
              }
            }
            'HTTP_-_Get_AzureAD_Applications': {
              runAfter: {}
              type: 'Http'
              inputs: {
                headers: {
                  Authorization: 'Bearer @{body(\'Parse_JSON_-_Retrieve_token_Info\')?[\'access_token\']}'
                }
                method: 'GET'
                uri: '@variables(\'NextLink\')'
              }
            }
            Parse_JSON: {
              runAfter: {
                'HTTP_-_Get_AzureAD_Applications': [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP_-_Get_AzureAD_Applications\')'
                schema: {
                  properties: {
                    properties: {
                      properties: {
                        '@@odata.context': {
                          properties: {
                            type: {
                              type: 'string'
                            }
                          }
                          type: 'object'
                        }
                        value: {
                          properties: {
                            items: {
                              properties: {
                                properties: {
                                  properties: {
                                    '@@odata.id': {
                                      properties: {
                                        type: {
                                          type: 'string'
                                        }
                                      }
                                      type: 'object'
                                    }
                                    appId: {
                                      properties: {
                                        type: {
                                          type: 'string'
                                        }
                                      }
                                      type: 'object'
                                    }
                                    displayName: {
                                      properties: {
                                        type: {
                                          type: 'string'
                                        }
                                      }
                                      type: 'object'
                                    }
                                    keyCredentials: {
                                      properties: {
                                        type: {
                                          type: 'string'
                                        }
                                      }
                                      type: 'object'
                                    }
                                    passwordCredentials: {
                                      properties: {
                                        items: {
                                          properties: {
                                            properties: {
                                              properties: {
                                                customKeyIdentifier: {
                                                  properties: {}
                                                  type: 'object'
                                                }
                                                displayName: {
                                                  properties: {
                                                    type: {
                                                      type: 'string'
                                                    }
                                                  }
                                                  type: 'object'
                                                }
                                                endDateTime: {
                                                  properties: {
                                                    type: {
                                                      type: 'string'
                                                    }
                                                  }
                                                  type: 'object'
                                                }
                                                hint: {
                                                  properties: {
                                                    type: {
                                                      type: 'string'
                                                    }
                                                  }
                                                  type: 'object'
                                                }
                                                keyId: {
                                                  properties: {
                                                    type: {
                                                      type: 'string'
                                                    }
                                                  }
                                                  type: 'object'
                                                }
                                                secretText: {
                                                  properties: {}
                                                  type: 'object'
                                                }
                                                startDateTime: {
                                                  properties: {
                                                    type: {
                                                      type: 'string'
                                                    }
                                                  }
                                                  type: 'object'
                                                }
                                              }
                                              type: 'object'
                                            }
                                            required: {
                                              items: {
                                                type: 'string'
                                              }
                                              type: 'array'
                                            }
                                            type: {
                                              type: 'string'
                                            }
                                          }
                                          type: 'object'
                                        }
                                        type: {
                                          type: 'string'
                                        }
                                      }
                                      type: 'object'
                                    }
                                  }
                                  type: 'object'
                                }
                                required: {
                                  items: {
                                    type: 'string'
                                  }
                                  type: 'array'
                                }
                                type: {
                                  type: 'string'
                                }
                              }
                              type: 'object'
                            }
                            type: {
                              type: 'string'
                            }
                          }
                          type: 'object'
                        }
                      }
                      type: 'object'
                    }
                    type: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
              }
            }
            Update_Next_Link: {
              runAfter: {
                'Foreach_-_apps': [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'NextLink'
                value: '@{body(\'Parse_JSON\')?[\'@odata.nextLink\']}'
              }
            }
          }
          runAfter: {
            'Initialize_-_NextLink': [
              'Succeeded'
            ]
          }
          expression: '@not(equals(variables(\'NextLink\'), null))'
          limit: {
            count: 60
            timeout: 'PT1H'
          }
          type: 'Until'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          keyvault: {
            connectionId: connections_keyvault_externalid
            connectionName: keyVaultConn
            id: keyVaultConn_id
          }
          office365: {
            connectionId: connections_office365_externalid
            connectionName: o365Conn
            id: o365Conn_id
          }
        }
      }
    }
  }
}
