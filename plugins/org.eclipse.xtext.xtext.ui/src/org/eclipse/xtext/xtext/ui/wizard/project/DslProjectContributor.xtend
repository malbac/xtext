package org.eclipse.xtext.xtext.ui.wizard.project

import org.eclipse.core.resources.IProject
import org.eclipse.xtext.ui.util.IProjectFactoryContributor.IFileCreator

/**
 * Contributes a workflow file and the grammar to the new DSL project
 * @author Dennis Huebner - Initial contribution and API
 * @since 2.3
 */
class DslProjectContributor extends DefaultProjectFactoryContributor {

	XtextProjectInfo projectInfo
	String sourceRoot

	new(XtextProjectInfo projectInfo) {
		this.projectInfo = projectInfo
	}

	def void setSourceRoot(String sourceRoot) {
		this.sourceRoot = sourceRoot
	}

	override contributeFiles(IProject project, IFileCreator it) {
		writeToFile(workflow(project.
			defaultCharset), '''«sourceRoot»/«projectInfo.basePackagePath»/Generate«projectInfo.languageNameAbbreviation».mwe2''')
		writeToFile(grammar, sourceRoot + "/" + projectInfo.grammarFilePath)
		writeToFile(
			wfLaunchConfig, '''.launch/Generate «projectInfo.getLanguageNameAbbreviation» («projectInfo.fileExtension») Language Infrastructure.launch''')
		if (projectInfo.createEclipseRuntimeLaunchConfig && projectInfo.isCreateUiProject) {
			writeToFile(launchConfig, ".launch/Launch Runtime Eclipse.launch")
		}
	}

	def private workflow(String encoding) {
		''' 
			module «(projectInfo.basePackagePath+"/Generate"+projectInfo.languageNameAbbreviation).replaceAll("/", ".")»
			
			import org.eclipse.emf.mwe.utils.*
			import org.eclipse.xtext.generator.*
			import org.eclipse.xtext.ui.generator.*
			
			var grammarURI = "classpath:/«projectInfo.basePackagePath»/«projectInfo.languageNameAbbreviation».xtext"
			var fileExtensions = "«projectInfo.fileExtension»"
			var projectName = "«projectInfo.projectName»"
			var runtimeProject = "../${projectName}"
			var generateXtendStub = true
			var encoding = "«encoding»"
			var fileHeader = "/*\n * generated by Xtext \${version}\n */"
			«IF projectInfo.createIntellijProject»
				var ideaProjectName = "${projectName}.idea"
				var ideaProjectPath = "../${ideaProjectName}"
			«ENDIF»
			Workflow {
			    bean = StandaloneSetup {
					scanClassPath = true
					platformUri = "${runtimeProject}/.."
					// The following two lines can be removed, if Xbase is not used.
					registerGeneratedEPackage = "org.eclipse.xtext.xbase.XbasePackage"
					registerGenModelFile = "platform:/resource/org.eclipse.xtext.xbase/model/Xbase.genmodel"
				}
				
				component = DirectoryCleaner {
					directory = "${runtimeProject}/src-gen"
				}
				
				component = DirectoryCleaner {
					directory = "${runtimeProject}/model/generated"
				}
				
				«IF projectInfo.isCreateUiProject»
					component = DirectoryCleaner {
						directory = "${runtimeProject}.ui/src-gen"
					}
				«ENDIF»
				
				«IF projectInfo.isCreateTestProject»
					component = DirectoryCleaner {
						directory = "${runtimeProject}.tests/src-gen"
					}
				«ENDIF»
				«IF projectInfo.isCreateIdeProject»
					component = DirectoryCleaner {
						directory = "${runtimeProject}.ide/src-gen"
					}
				«ENDIF»
				«IF projectInfo.isCreateIntellijProject»
					component = DirectoryCleaner {
						directory = "${ideaProjectPath}/src-gen"
					}
				«ENDIF»
				
				component = Generator auto-inject {
					pathRtProject = runtimeProject
					projectNameRt = projectName
					«IF projectInfo.isCreateUiProject»
						pathUiProject = "${runtimeProject}.ui"
						projectNameUi = "${projectName}.ui"
					«ENDIF»
					«IF projectInfo.isCreateTestProject»
						pathTestProject = "${runtimeProject}.tests"
					«ENDIF»
					«IF projectInfo.isCreateIdeProject»
						pathIdeProject = "${runtimeProject}.ide"
						projectNameIde = "${projectName}.ide"
					«ENDIF»
					language = auto-inject {
						uri = grammarURI
			
						// Java API to access grammar elements (required by several other fragments)
						fragment = grammarAccess.GrammarAccessFragment auto-inject {}
			
						// generates Java API for the generated EPackages
						fragment = ecore.EMFGeneratorFragment auto-inject {}
			
						fragment = serializer.SerializerFragment auto-inject {
							generateStub = false
						}
			
						// a custom ResourceFactory for use with EMF
						fragment = resourceFactory.ResourceFactoryFragment auto-inject {}
			
						// The antlr parser generator fragment.
						fragment = parser.antlr.XtextAntlrGeneratorFragment auto-inject {
						//  options = {
						//      backtrack = true
						//  }
						}
			
						// Xtend-based API for validation
						fragment = validation.ValidatorFragment auto-inject {
						//    composedCheck = "org.eclipse.xtext.validation.ImportUriValidator"
						//    composedCheck = "org.eclipse.xtext.validation.NamesAreUniqueValidator"
						}
			
						// scoping and exporting API
						fragment = scoping.ImportNamespacesScopingFragment auto-inject {}
						fragment = exporting.QualifiedNamesFragment auto-inject {}
			
						// generator API
						fragment = generator.GeneratorFragment auto-inject {}
			
						// formatter API
						fragment = formatting.FormatterFragment auto-inject {}
						
						«IF projectInfo.isCreateTestProject»
							// generates junit test support classes into Generator#pathTestProject
							fragment = junit.Junit4Fragment auto-inject {}
						«ENDIF»
						
						«IF projectInfo.isCreateUiProject»
							fragment = builder.BuilderIntegrationFragment auto-inject {}
							// labeling API
							fragment = labeling.LabelProviderFragment auto-inject {}
							
							// outline API
							fragment = outline.OutlineTreeProviderFragment auto-inject {}
							fragment = outline.QuickOutlineFragment auto-inject {}
							
							// quickfix API
							fragment = quickfix.QuickfixProviderFragment auto-inject {}
							
							// content assist API
							fragment = contentAssist.ContentAssistFragment auto-inject {}
							
							// generates a more lightweight Antlr parser and lexer tailored for content assist
							fragment = parser.antlr.XtextAntlrUiGeneratorFragment auto-inject {}
							// provides a preference page for template proposals
							fragment = templates.CodetemplatesGeneratorFragment auto-inject {}
							
							// rename refactoring
							fragment = refactoring.RefactorElementNameFragment auto-inject {}
							
							// provides a compare view
							fragment = compare.CompareFragment auto-inject {}
						«ENDIF»
						// provides the necessary bindings for java types integration
						fragment = types.TypesGeneratorFragment auto-inject {}
			
						// generates the required bindings only if the grammar inherits from Xbase
						fragment = xbase.XbaseGeneratorFragment auto-inject {}
			
						// generates the required bindings only if the grammar inherits from Xtype
						fragment = xbase.XtypeGeneratorFragment auto-inject {}
						«IF projectInfo.createIntellijProject»
							fragment = org.eclipse.xtext.idea.generator.IdeaPluginGenerator auto-inject {
								runtimeProjectName = projectName
								runtimeProjectPath = runtimeProject
							}
							fragment = org.eclipse.xtext.idea.generator.parser.antlr.XtextAntlrIDEAGeneratorFragment auto-inject {}
						«ENDIF»
					}
				}
			}
		'''
	}

	def private grammar() {
		'''
			grammar «projectInfo.languageName» with org.eclipse.xtext.common.Terminals
			
			generate «projectInfo.languageNameAbbreviation.toFirstLower» "«projectInfo.nsURI»"
			
			Model:
				greetings+=Greeting*;
				
			Greeting:
				'Hello' name=ID '!';
		'''
	}

	def private wfLaunchConfig() {
		var projectsToRefresh = '''&lt;item path=&quot;/«projectInfo.projectName»&quot; type=&quot;4&quot;/&gt;&#10;'''
		if (projectInfo.createIdeProject)
			projectsToRefresh +=
				'''&lt;item path=&quot;/«projectInfo.ideProjectName»&quot; type=&quot;4&quot;/&gt;&#10'''
		if (projectInfo.createIntellijProject)
			projectsToRefresh +=
				''';&lt;item path=&quot;/«projectInfo.intellijProjectName»&quot; type=&quot;4&quot;/&gt;&#10;'''
		if (projectInfo.createTestProject)
			projectsToRefresh +=
				''';&lt;item path=&quot;/«projectInfo.testProjectName»&quot; type=&quot;4&quot;/&gt;&#10;'''
		if (projectInfo.createUiProject)
			projectsToRefresh +=
				'''&lt;item path=&quot;/«projectInfo.uiProjectName»&quot; type=&quot;4&quot;/&gt;&#10'''

		val refreshAttr = '''${working_set:&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;&#10;&lt;resources&gt;&#10;«projectsToRefresh»;&lt;/resources&gt;}'''

		'''
			<?xml version="1.0" encoding="UTF-8" standalone="no"?>
			<launchConfiguration type="org.eclipse.emf.mwe2.launch.Mwe2LaunchConfigurationType">
			<stringAttribute key="org.eclipse.debug.core.ATTR_REFRESH_SCOPE" value="«refreshAttr»"/>
			<listAttribute key="org.eclipse.debug.core.MAPPED_RESOURCE_PATHS">
			<listEntry value="/«projectInfo.projectName»"/>
			</listAttribute>
			<listAttribute key="org.eclipse.debug.core.MAPPED_RESOURCE_TYPES">
			<listEntry value="4"/>
			</listAttribute>
			<listAttribute key="org.eclipse.debug.ui.favoriteGroups">
			<listEntry value="org.eclipse.debug.ui.launchGroup.debug"/>
			<listEntry value="org.eclipse.debug.ui.launchGroup.run"/>
			</listAttribute>
			<stringAttribute key="org.eclipse.jdt.launching.MAIN_TYPE" value="org.eclipse.emf.mwe2.launch.runtime.Mwe2Launcher"/>
			<stringAttribute key="org.eclipse.jdt.launching.PROGRAM_ARGUMENTS" value="src/«projectInfo.basePackagePath»/Generate«projectInfo.languageNameAbbreviation».mwe2"/>
			<stringAttribute key="org.eclipse.jdt.launching.PROJECT_ATTR" value="«projectInfo.projectName»"/>
			<stringAttribute key="org.eclipse.jdt.launching.VM_ARGUMENTS" value="-Xmx512m"/>
			</launchConfiguration>
		'''
	}

	def private launchConfig() {
		'''
			<?xml version="1.0" encoding="UTF-8" standalone="no"?>
			<launchConfiguration type="org.eclipse.pde.ui.RuntimeWorkbench">
			<booleanAttribute key="append.args" value="true"/>
			<booleanAttribute key="askclear" value="true"/>
			<booleanAttribute key="automaticAdd" value="true"/>
			<booleanAttribute key="automaticValidate" value="false"/>
			<stringAttribute key="bad_container_name" value="/«projectInfo.projectName»/.launch/"/>
			<stringAttribute key="bootstrap" value=""/>
			<stringAttribute key="checked" value="[NONE]"/>
			<booleanAttribute key="clearConfig" value="false"/>
			<booleanAttribute key="clearws" value="false"/>
			<booleanAttribute key="clearwslog" value="false"/>
			<stringAttribute key="configLocation" value="${workspace_loc}/.metadata/.plugins/org.eclipse.pde.core/Launch Runtime Eclipse"/>
			<booleanAttribute key="default" value="true"/>
			<booleanAttribute key="includeOptional" value="true"/>
			<stringAttribute key="location" value="${workspace_loc}/../runtime-EclipseXtext"/>
			<listAttribute key="org.eclipse.debug.ui.favoriteGroups">
			<listEntry value="org.eclipse.debug.ui.launchGroup.debug"/>
			<listEntry value="org.eclipse.debug.ui.launchGroup.run"/>
			</listAttribute>
			<stringAttribute key="org.eclipse.jdt.launching.JRE_CONTAINER" value="org.eclipse.jdt.launching.JRE_CONTAINER/org.eclipse.jdt.internal.debug.ui.launcher.StandardVMType/J2SE-1.5"/>
			<stringAttribute key="org.eclipse.jdt.launching.PROGRAM_ARGUMENTS" value="-os ${target.os} -ws ${target.ws} -arch ${target.arch} -nl ${target.nl}"/>
			<stringAttribute key="org.eclipse.jdt.launching.SOURCE_PATH_PROVIDER" value="org.eclipse.pde.ui.workbenchClasspathProvider"/>
			<stringAttribute key="org.eclipse.jdt.launching.VM_ARGUMENTS" value="-Xms40m -Xmx512m -XX:MaxPermSize=256m"/>
			<stringAttribute key="pde.version" value="3.3"/>
			<stringAttribute key="product" value="org.eclipse.platform.ide"/>
			<booleanAttribute key="show_selected_only" value="false"/>
			<stringAttribute key="templateConfig" value="${target_home}/configuration/config.ini"/>
			<booleanAttribute key="tracing" value="false"/>
			<booleanAttribute key="useDefaultConfig" value="true"/>
			<booleanAttribute key="useDefaultConfigArea" value="true"/>
			<booleanAttribute key="useProduct" value="true"/>
			<booleanAttribute key="usefeatures" value="false"/>
			</launchConfiguration>
		'''
	}
}