package org.eclipse.xtext.xbase.idea;

import org.eclipse.xtext.util.Modules2;
import org.eclipse.xtext.xbase.XbaseStandaloneSetupGenerated;

import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;

public class XbaseStandaloneSetupIdea extends XbaseStandaloneSetupGenerated {

    @Override
    public Injector createInjector() {
        Module runtimeModule = new org.eclipse.xtext.xbase.XbaseRuntimeModule();
        Module ideaModule = new org.eclipse.xtext.xbase.idea.XbaseIdeaModule();
        Module mergedModule = Modules2.mixin(runtimeModule, ideaModule);
        return Guice.createInjector(mergedModule);
    }

}