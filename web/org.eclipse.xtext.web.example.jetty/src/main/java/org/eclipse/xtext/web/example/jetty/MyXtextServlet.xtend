/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.web.example.jetty

import com.google.inject.Binder
import com.google.inject.Guice
import com.google.inject.name.Names
import org.eclipse.xtext.ide.LexerIdeBindings
import org.eclipse.xtext.ide.editor.contentassist.antlr.IContentAssistParser
import org.eclipse.xtext.ide.editor.contentassist.antlr.internal.Lexer
import org.eclipse.xtext.idea.example.entities.EntitiesRuntimeModule
import org.eclipse.xtext.idea.example.entities.EntitiesStandaloneSetup
import org.eclipse.xtext.idea.example.entities.ide.contentassist.antlr.EntitiesParser
import org.eclipse.xtext.idea.example.entities.ide.contentassist.antlr.internal.InternalEntitiesLexer
import org.eclipse.xtext.service.AbstractGenericModule
import org.eclipse.xtext.web.example.jetty.MyXtextServlet.EntitiesIdeModule
import org.eclipse.xtext.web.server.persistence.FileResourceHandler
import org.eclipse.xtext.web.server.persistence.IResourceBaseProvider
import org.eclipse.xtext.web.server.persistence.IServerResourceHandler
import org.eclipse.xtext.web.server.persistence.ResourceBaseProviderImpl
import org.eclipse.xtext.web.servlet.XtextServlet
import javax.servlet.annotation.WebServlet

@WebServlet(name = "Xtext Services", urlPatterns = "/xtext-services/*")
class MyXtextServlet extends XtextServlet {

	override init() {
		new EntitiesStandaloneSetup {
			override createInjector() {
				return Guice.createInjector(new EntitiesRuntimeModule, new EntitiesIdeModule)
			}
		}.createInjectorAndDoEMFRegistration
		super.init()
	}

	static class EntitiesIdeModule extends AbstractGenericModule {
		
		def configureContentAssistLexer(Binder binder) {
			binder.bind(Lexer).annotatedWith(Names.named(LexerIdeBindings.CONTENT_ASSIST)).to(InternalEntitiesLexer)
		}

		def Class<? extends IContentAssistParser> bindIContentAssistParser() {
			EntitiesParser
		}
		
		def Class<? extends IServerResourceHandler> bindIServerResourceHandler() {
			FileResourceHandler
		}
		
		def configureResourceBaseProvider(Binder binder) {
			binder.bind(IResourceBaseProvider).toInstance(new ResourceBaseProviderImpl(resourceBase))
		}
	
		private def getResourceBase() {
			// This relative path assumes the working directory is the server project base directory
			'./test-files'
		}
	}

}