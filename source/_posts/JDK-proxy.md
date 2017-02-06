---
title: JDK 动态代理机制

date: 2017-02-06 17:01:53
categories:
 - java

tags:
 - aop
 - proxy
 
author: jeffor
---

## 简述

**JDK 动态代理是一种`基于反射`的`运行时`逻辑切入。实现简单，但只作用于`接口级别`。以下示例将一步步演示其实现过程并分析其实现特点及应用场景。**

<!-- more -->

---

## 一、java 动态代理实现简述

### - UML 类图描述:

![JDK-proxy](/images/JDK-proxy.png)

- 类图分析:
 1. 从类图关系可以看出，`代理逻辑(ProxyHandler)`和`业务逻辑(BusinessImpl)`在定义时是相互独立的。
 2. 代理对象是由`Proxy.newProxyInstance()` 方法生成, 该方法强依赖于 `代理逻辑实例(InvocationHandler实例对象)` 和 `被代理业务接口(IBusiness)`。

> 类图总结:
>  通过分析我们可以得出代理对象的创建必须依赖具体代理逻辑的定义和被代理接口的定义。创建代理的过程可以分为如下几步:
> 
>   1. 定义并明确需要被代理的业务接口;
>   2. 实现 `InvocationHandler` 接口，创建代理逻辑实例类;
>   3. 通过 `Proxy.newProxyInstance()` 方法创建具体代理对象
> 
> __需要注意的是 `InvocationHandler` 实例类也依赖具体的业务对象，因为在代理进行方法调用时必须明确自己代理的目标对象是什么。__

---

## 二、JDK 动态代理样例实现

### - 定义业务接口和业务实现类

业务接口和实现类完全根据业务需求进行定义和实现，这里只做简单 **demo** 演示，故只是实现了一个简介的 **doBusiness** 方法:

1. 业务接口:

	```
	
	/**
	 * 业务接口
	 */
	public interface IBusiness {
	
	    /**
	     * 业务方法
	     *
	     * @param business 业务参数
	     * @return 执行成功返回 true, 失败返回 false
	     * @throws IllegalArgumentException 参数异常时抛出
	     */
	    public Boolean doBusiness(String business) throws IllegalArgumentException;
	}
	```

2. 业务实例类:

	```
	
	import org.apache.commons.lang3.Validate;
	
	/**
	 * 业务细节实现类
	 */
	public class BusinessImpl implements IBusiness {
	
	    /**
	     * 业务方法
	     *
	     * @param business 业务参数
	     * @return 执行成功返回 true, 失败返回 false
	     * @throws IllegalArgumentException 参数异常时抛出
	     */
	    public Boolean doBusiness(
	            String business) throws IllegalArgumentException {
	
	        Validate.notBlank(business);                        // 参数校验
	        System.out.println("Do business: " + business);     // 业务逻辑
	        return true;                                        // 业务返回
	    }
	}
	
	```

### - 代理逻辑定义(InvocationHandler实现)

代理逻辑区别于普通业务逻辑，他可以是基于框架功能的抽象，也可以是更泛化的业务逻辑抽象，但是他的功能应该是明确的: 代理的存在一方面让具体业务实例在进行业务操作时更加纯粹(干净), 另外也使抽象逻辑的管理更加统一。

常见的代理逻辑如: `调用日志记录`，`监控打点`，`会话管理`，`资源回收` 等。这里我们只做简单的打印实现（主要是方便观察效果 ^^）:

	```
	
	import java.lang.reflect.InvocationHandler;
	import java.lang.reflect.Method;
	
	/**
	 * 代理操作类
	 *
	 * 其作用是定义具体的代理逻辑
	 */
	public class ProxyHandler implements InvocationHandler {
	
	    private Object businessObject;
	
	    /**
	     * 该案例通过构造函数设置被代理对象(可选)
	     */
	    public ProxyHandler(Object businessObject) {
	        this.businessObject = businessObject;
	    }
	
	    /**
	     * 具体代理逻辑切入实现
	     *
	     * 可以实现的功能:
	     *
	     * 1. 逻辑织入(调用前后增加非业务逻辑)
	     *
	     * 2. 控制调用姿势(根据上下文方法控制调用方式)
	     *
	     * 3. 返回值和异常控制
	     *
	     * @param proxy  代理对象
	     * @param method 被调用的业务接口方法
	     * @param args   被调用业务接口方法的参数
	     */
	    @Override
	    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
	        System.out.println("Do something before method");
	        Object result = businessObject == null ? null : method.invoke(businessObject, args);
	        System.out.println("Do something after method");
	        return result;
	    }
	}
	```

> 可以看出代理逻辑的实现还是比较简单清晰的，这里做了被调方法在调用前后的操作(打印)，方法调用时的判断操作以及返回值的传递操作。不难发现代理对调用的控制相当全面，他直接决定了方法是否真正调用。
> 
> **需要注意的是**: 因为基于反射的method方法调用必须依赖具体执行对象作为参数，所以调用逻辑在实现时也需要依赖具体的业务实例。（本例中在构造函数中引入实例引用，当然也可以以set方法的的形式传入，这样还可以达到意想不到的效果哦 ^ ^ )


### - 代理对象的创建和使用(Proxy.newProxyInstance())

豪爽的我直接上代码:

	```
	
	import java.lang.reflect.Proxy;
	
	/**
	 * JDK 动态代场景理测试
	 */
	public class ProxyTest {
	
	    public static void main(String... args) {
	
	        BusinessImpl business = new BusinessImpl();                 // 业务对象实例
	        ProxyHandler proxyHandler = new ProxyHandler(business);     // 代理逻辑执行器对象
	
	        /**创建代理对象*/
	        IBusiness businessProxy = (IBusiness) Proxy.newProxyInstance(
	                business.getClass().getClassLoader(),
	                new Class[]{IBusiness.class},
	                proxyHandler);
	
	
	        businessProxy.doBusiness("business");    // 处理业务
	
	    }
	}
	```
	
寥寥几行, 不要太简单！！代理对象的创建只需三个参数:

 1. 被代理对象的类加载器;
 2. 被代理的接口列表;
 3. 刚刚定义的代理逻辑实例对象;

接下来让我们看看执行效果:
	
	```
	Do something before method
	Do business: business
	Do something after method
	```
	
哈哈~ 代理逻辑已经完美执行!

---

## 三、JDK 动态代理特性分析

上面已经说过，代理的存在一方面让具体业务实例在进行业务操作时更加纯粹(干净), 另外也使抽象逻辑的管理更加统一。需要指出的是 `JDK 动态代理` 只是众多代理实现方式中的一种，如在`spring`框架中，其AOP实现就综合了 `JDK 动态代理` 和 `CGLIB 代理` 。接下来让我们总结一下 `JDK 动态代理` 的特点:

  1. JDK 原生支持，无需依赖第三方库；
  2. `JDK 动态代理` 实质上为运行时通过代理对象间接调用目标对象方法达到逻辑切入目的（并不修改原有业务逻辑）
  3. 依赖业务接口。代理对象在生成时强依赖于被代理的业务接口，因此在使用过程中可能会增加不必要的接口定义（不支持方法粒度代理）。
  4. 代理逻辑实现方便，但也过于简陋。对于被代理对象，他的所有方法在调用时都会执行代理逻辑类中的`invoke`方法，这也说明在唯一的一个`invoke`方法中必须cover目标对象中所有方法的执行逻辑。很显然，当接口中存在代理逻辑不一致的方法时，这种方式很容易造成不必要的耦合，不便于代理逻辑开发维护（代理逻辑定义时容易耦合）。

---

## 四、总结

  代理的应用在框架类型的项目开发中是很常见的，其重要性不言而喻。本篇简单介绍了原生的`JDK 动态代理`，其实现简单，逻辑清晰。可以看出在普通面向接口，切入逻辑简单且统一的代理实现上，`JDK 动态代理`是一个不错的选择，但是面对更细致的代理场景，如跨接口的方法级别代理需求，`JDK 动态代理`便显得余力不足了。后面的博文中向大家介绍一个方法级别的代理库----`CGLIB`,它也是 `spring AOP` 代理实现中的重要一员。
