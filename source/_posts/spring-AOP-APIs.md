---
title: spring AOP APIs 简述
date: 2017-02-04 18:01:53
categories:
 - java
 - spring
tags: 
 - aop
author: jeffor
---

## 1. Pointcut API

### 1.1 接口定义:

  spring pointcut 用于将 `advices` 指向特定的类和方法。其具体定义如下:

<!-- more -->

	```
	package org.springframework.aop;
	
	/**
	 * Core Spring pointcut abstraction.
	 *
	 * <p>A pointcut is composed of a {@link ClassFilter} and a {@link MethodMatcher}.
	 * Both these basic terms and a Pointcut itself can be combined to build up combinations
	 * (e.g. through {@link org.springframework.aop.support.ComposablePointcut}).
	 *
	 * @author Rod Johnson
	 * @see ClassFilter
	 * @see MethodMatcher
	 * @see org.springframework.aop.support.Pointcuts
	 * @see org.springframework.aop.support.ClassFilters
	 * @see org.springframework.aop.support.MethodMatchers
	 */
	public interface Pointcut {
	
		/**
		 * Return the ClassFilter for this pointcut.
		 * @return the ClassFilter (never {@code null})
		 */
		ClassFilter getClassFilter();
	
		/**
		 * Return the MethodMatcher for this pointcut.
		 * @return the MethodMatcher (never {@code null})
		 */
		MethodMatcher getMethodMatcher();
	
	
		/**
		 * Canonical Pointcut instance that always matches.
		 */
		Pointcut TRUE = TruePointcut.INSTANCE;
	
	}
	```
	
	可以看出 pointcut 接口分成 `类型匹配` 和 `方法匹配` 两个部分, 它们共同实现了切点的识别;
	
- ClassFilter 接口:

 ClassFilter 用来指定需要切入的目标类型。其接口定义如下:
 
	```
	 /*
	 * Copyright 2002-2007 the original author or authors.
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 *      http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 */
	
	package org.springframework.aop;
	
	/**
	 * Filter that restricts matching of a pointcut or introduction to
	 * a given set of target classes.
	 *
	 * <p>Can be used as part of a {@link Pointcut} or for the entire
	 * targeting of an {@link IntroductionAdvisor}.
	 *
	 * @author Rod Johnson
	 * @see Pointcut
	 * @see MethodMatcher
	 */
	public interface ClassFilter {
	
		/**
		 * Should the pointcut apply to the given interface or target class?
		 * @param clazz the candidate target class
		 * @return whether the advice should apply to the given target class
		 */
		boolean matches(Class<?> clazz);
	
	
		/**
		 * Canonical instance of a ClassFilter that matches all classes.
		 */
		ClassFilter TRUE = TrueClassFilter.INSTANCE;
	
	}
	```
	
	如果 matches 方法返回 `true` 则对应的类将被选中为通知类型;
	
- MethodMatcher 接口:

 MethodMatcher 接口是一个更为重要的接口, 其具体实现如下:
 
	```
	 /*
	 * Copyright 2002-2012 the original author or authors.
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 *      http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 */
	
	package org.springframework.aop;
	
	import java.lang.reflect.Method;
	
	/**
	 * Part of a {@link Pointcut}: Checks whether the target method is eligible for advice.
	 *
	 * <p>A MethodMatcher may be evaluated <b>statically</b> or at <b>runtime</b> (dynamically).
	 * Static matching involves method and (possibly) method attributes. Dynamic matching
	 * also makes arguments for a particular call available, and any effects of running
	 * previous advice applying to the joinpoint.
	 *
	 * <p>If an implementation returns {@code false} from its {@link #isRuntime()}
	 * method, evaluation can be performed statically, and the result will be the same
	 * for all invocations of this method, whatever their arguments. This means that
	 * if the {@link #isRuntime()} method returns {@code false}, the 3-arg
	 * {@link #matches(java.lang.reflect.Method, Class, Object[])} method will never be invoked.
	 *
	 * <p>If an implementation returns {@code true} from its 2-arg
	 * {@link #matches(java.lang.reflect.Method, Class)} method and its {@link #isRuntime()} method
	 * returns {@code true}, the 3-arg {@link #matches(java.lang.reflect.Method, Class, Object[])}
	 * method will be invoked <i>immediately before each potential execution of the related advice</i>,
	 * to decide whether the advice should run. All previous advice, such as earlier interceptors
	 * in an interceptor chain, will have run, so any state changes they have produced in
	 * parameters or ThreadLocal state will be available at the time of evaluation.
	 *
	 * @author Rod Johnson
	 * @since 11.11.2003
	 * @see Pointcut
	 * @see ClassFilter
	 */
	public interface MethodMatcher {
	
		/**
		 * Perform static checking whether the given method matches. If this
		 * returns {@code false} or if the {@link #isRuntime()} method
		 * returns {@code false}, no runtime check (i.e. no.
		 * {@link #matches(java.lang.reflect.Method, Class, Object[])} call) will be made.
		 * @param method the candidate method
		 * @param targetClass the target class (may be {@code null}, in which case
		 * the candidate class must be taken to be the method's declaring class)
		 * @return whether or not this method matches statically
		 */
		boolean matches(Method method, Class<?> targetClass);
	
		/**
		 * Is this MethodMatcher dynamic, that is, must a final call be made on the
		 * {@link #matches(java.lang.reflect.Method, Class, Object[])} method at
		 * runtime even if the 2-arg matches method returns {@code true}?
		 * <p>Can be invoked when an AOP proxy is created, and need not be invoked
		 * again before each method invocation,
		 * @return whether or not a runtime match via the 3-arg
		 * {@link #matches(java.lang.reflect.Method, Class, Object[])} method
		 * is required if static matching passed
		 */
		boolean isRuntime();
	
		/**
		 * Check whether there a runtime (dynamic) match for this method,
		 * which must have matched statically.
		 * <p>This method is invoked only if the 2-arg matches method returns
		 * {@code true} for the given method and target class, and if the
		 * {@link #isRuntime()} method returns {@code true}. Invoked
		 * immediately before potential running of the advice, after any
		 * advice earlier in the advice chain has run.
		 * @param method the candidate method
		 * @param targetClass the target class (may be {@code null}, in which case
		 * the candidate class must be taken to be the method's declaring class)
		 * @param args arguments to the method
		 * @return whether there's a runtime match
		 * @see MethodMatcher#matches(Method, Class)
		 */
		boolean matches(Method method, Class<?> targetClass, Object[] args);
	
	
		/**
		 * Canonical instance that matches all methods.
		 */
		MethodMatcher TRUE = TrueMethodMatcher.INSTANCE;
	
	}
	```
	
	当创建 proxy 对象时， `matches(Method method, Class<?> targetClass);`方法将被调用，该方法用于判断当前类的方法是否为切入点，
这个方法不会在目标对象被调用时执行。当 该方法返回`true` 且 `isRuntime()`方法返回 `true`时，每次调用目标对象的该方法都会触发 `matches(Method method, Class<?> targetClass, Object[] args)` 方法的调用， 此时会判断参数信息是否符合切入点匹配规则。大部分 `MethodMatcher` 都是静态的，这意味着 `isRuntime()`方法都是返回`false`,这样的Matcher将不会在目标对象调用时检测方法是否匹配切入规则。


### 1.2 对Pointcut的操作:

 spring 支持对 Pointcut 进行`交并补`操作:
 
 1. 交集操作意味着一个方法必须被所有的 pointcut 匹配通过;
 2. 并集操作意味着一个方法只需被任意一个 pointcut 匹配通过;

 
### 1.3 方便的 Pointcut 现有类实现:

  spring 提供了一系列Pointcut实例类,一些开箱即用，一些需要根据特定的应用场景集成实现特定的实例类。
  
  1. 静态 pointcut:

   静态 pointcut 不基于方法调用时传入参数作为切点判断依据。它们只在 代理对象初始化时对类方法进行切入评估，因此更高效。以下是一些静态 pointcut 的实例类;
   
  2. 动态 pointcut:

   相对于静态pointcut, 动态pointcut基于调用时传入的参数或其他运行时信息(如堆栈信息)评估方法切入。因此动态 pointcut 将在每次方法调用时进行评估，其消耗型相对较高;
   
   
---

## 2. Advice API

### 2.1 advice 的生命周期:

advice 可以分成 `per-class` 和 `per-instance` 两种。

1. per-class Advice 生命周期: 这种类型的Advice是无状态的，他只基于方法和参数实现通知逻辑，因此它可以被多个被通知对象共享。
2. per-instance Advice 生命周期: 这种类型的 Advice 通过特定的状态信息实现一些高级功能，因此其生命周期和具体的被代理实例对象相对应。

### 2.2 spring 中的 Advice:

spring 提供了一系列开箱即用的 Advice 类型:

1. interception around advice:

	```
	public class DebugInterceptor implements MethodInterceptor {     public Object invoke(
     		MethodInvocation invocation) throws Throwable {
      	System.out.println("Before: invocation=[" + invocation + "]");
        Object rval = invocation.proceed();
        System.out.println("Invocation returned");
        return rval; 
        }	}
	```

2. Before advice

	```
	public class CountingBeforeAdvice implements MethodBeforeAdvice {
    
        private int count;	
		public void before(Method m, Object[] args, Object target) throws Throwable { 
			++count;
        }

        public int getCount() {
			return count;
		} 
	}
	```
	
3. Throws advice
	
	```
	public static class CombinedThrowsAdvice implements ThrowsAdvice {
	
        public void afterThrowing(
		    RemoteException ex) throws Throwable {
			// Do something with remote exception
        }
		
        public void afterThrowing(
			Method m, Object[] args, Object target, ServletException ex{ 
			// Do something with all arguments
        }
	}
	```

4. After Returning advice
	
	```
    public class CountingAfterReturningAdvice implements AfterReturningAdvice {
	 	
        private int count;
        
        public void afterReturning(
            Object returnValue, Method m, Object[] args, Object target) throws Throwable {
            ++count; 
		}
        
        public int getCount() {
			return count;
		}
	}
	```
	
5. Introduction advice
	
	```
	/** 
	 * 引入接口定义
	 */
	public interface Lockable {
		void lock();
        void unlock();
        boolean locked(); 
	}
	
	/**
	 * IntroductionIntecptor 定义
	 * IntroductionIntecptor 需要实现被引入的接口
	 * invoke 方法定义了拦截逻辑（覆写可选）
	 */
     public class LockMixin extends DelegatingIntroductionInterceptor implements Lockable {

        private boolean locked;
		
        public void lock() {
			this.locked = true;
        }
		
        public void unlock() {
			this.locked = false;
        }
		
        public boolean locked() {
			return this.locked;
        }
		
        public Object invoke(MethodInvocation invocation) throws Throwable {
            if (locked() && invocation.getMethod().getName().indexOf("set") == 0) {
                throw new LockedException();
			}
            
            return super.invoke(invocation); 
		}
        
    }
	
	/**
	 * IntroductionAdvisor 定义
	 * IntroductionAdvisor 定义了 引入接口 和 默认IntroductionIntecptor实例类
	 */
	public class LockMixinAdvisor extends DefaultIntroductionAdvisor {
    
        public LockMixinAdvisor() {
            super(new LockMixin(), Lockable.class);
		}
	}
	
	```

## 3. Advisor API

spring 中，advisor 是包含了 advice 和 pointcut 的切面组合。除了特殊的 `Introduction advice（引入通知）`，任何advisor可以使用任何advice。`DefaultPointcutAdvisor` 是使用最频繁的 advisor。


