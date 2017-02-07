---
title: CGLIB 动态代理初讲

date: 2017-02-07 16:55:53
categories:
 - java
 - cglib

tags:
 - aop
 - proxy

author: jeffor

---

## 简述:

  CGLIB (Code Generation Library) 底层基于 [ASM](http://baike.baidu.com/subview/98042/8756650.htm#viewPageContent) 字节码处理框架, 能够在运行时生成新的java字节码，因此在动态代理方面使用广泛。相对于 `JDK 原生动态代理`, 它无需依赖接口，能够对任意类生成代理对象。

<!-- more -->

---

## 一、CGLIB 实现动态代理的一般步骤 

  在 **CGLIB** 中存在一个关键类 **Enhancer**。众所周知，代理要对原有对象对外暴露功能进行托管和增强，对于一个业务对象，狭义上的对外契约可以认为是业务接口，但是广义而言，任意对象的 `public` 方法都可以认为是暴露于外部的契约。因此在 **CGLIB** 中，其代理类的创建可以依赖任意类(区别于  `JDK 原生动态代理` 的面向接口代理)。

  CGLIB 动态代理实现的简单步骤如下:
 
  ```
  Enhancer enhancer = new Enhancer();                     // 创建增强器
  enhancer.setSuperclass(businessObject.getClass());      // 设置被代理类
  enhancer.setCallback(callBackLogic);                    // 设置代理逻辑
  Business businessProxy = (Business)enhancer.create();   // 创建代理对象
            
  businessProxy.doBusiness();                             // 业务调用
  ```
 
  上面步骤中 `callBackLogic` 是代理逻辑调用器对象，定义了具体代理切入逻辑、方法调用方式等，为 **CGLIB** 中 `Callback` 接口的实例。**CGLIB** 中有许多不同的 **CallBack** 子接口，对应了各种不同功能的代理逻辑。
 
  - **CallBack** 子接口展示:
 
  ![**CallBack** 子接口](/images/callback-subinterface.png)

---
 
## 二、CGLIB 动态代理实现样例

老话讲,唯有实战才是磨炼技能的唯一标准，接下来我们根据一些简单样例分析 **CGLIB** 的特性:

### 依赖配置

- maven 依赖配置:

	```
	<!--cglib maven 依赖-->
	
	<dependency>
	    <groupId>cglib</groupId>
	    <artifactId>cglib</artifactId>
	    <version>3.2.4</version>
	</dependency>
	```

### FixedValue 代理逻辑调用器

- 功能介绍:

 FixedValue 增强器将为目标类(包含目标类的父类)的所有方法(准确而言应该是**非static且非final的public方法**)设置固定返回值。在代理对象调用任一方法时,预设置的返回值将被强制转换成对应方法定义的返回值类型。因此，当类型无法强制转换时会抛出 ClassCastException 异常;

- 样例代码展示:

	```
	import net.sf.cglib.proxy.Enhancer;
	import net.sf.cglib.proxy.FixedValue;
	
	
	/**
	 * FixedValue 测试
	 */
	public class CglibFixedValue {
	
	    public static void testFixedValue() {
	        Business business = new Business();
	
	        /**
	         * 初始化增强器
	         * */
	        Enhancer enhancer = new Enhancer();                     // 创建增强器
	        enhancer.setSuperclass(business.getClass());
	        enhancer.setCallback((FixedValue) () -> "do business by proxy");
	
	        /**
	         * 创建代理对象
	         * */
	        Business businessPrxy = (Business) enhancer.create();
	        System.out.println(business.doBusiness());
	        System.out.println(businessPrxy.doBusiness());
			 // System.out.println(businessPrxy.hashCode());          // err: ClassCastException
	
	        /**
	         * 创建代理增强类的类型
	         * */
	        Class cls = enhancer.createClass();
	        System.out.println(cls.getSuperclass().equals(business.getClass()));
			 // Date datePrxy = (Date) enhancer.create();             // err: ClassCastException
	    }
	
	    public static void main(String... args) {
	        testFixedValue();
	    }
	
		 /** 业务类定义 */
	    private static class Business {
	
	        public Business() {
	        }
	
	        // 静态方法
	        public static String staticDoBusiness() {
	            return "staticDoBusiness";
	        }
	
	        public String doBusiness() {
	            return "doBusiness";
	        }
	
	        final public String finalDoBusiness() {
	            return "finalDoBusiness";
	        }
	
	        private String privateDoBusiness(){
	            return "privateDoBusiness";
	        }
	
	        protected String protectedDoBusiness(){
	            return "protectedDoBusiness";
	        }
	    }
	}
	```
	
- 运行结果如下:

	```
	非代理对象业务调用: doBusiness
	业务方法代理调用: do business by proxy
	父类方法代理调用: do business by proxy
	代理增强类是否是业务类的子类: true
	```

  正如开始描述，FixedValue 将会设置目标类及其父类中的方法返回固定值。代码样例中注释部分调用将产生类型转换异常。需要注意的是**Business** 类中定义了静态方法(staticDoBusiness),final方法(finalDoBusiness),private方法(privateDoBusiness)和protected方法(protectedDoBusiness),我在debug模式使用控制台监控器调用结果如下:

 ![debug1](/images/debug1.jpeg)

 显然这些方法都未被代理重写。这是因为 **CGLIB** 只会对 **非final且非static的public方法** 进行代理逻辑重写。

### InvocationHandler 代理逻辑调用器

 - **CGLIB** 和 **JDK原生动态代理** 一样也支持 **InvocationHandler** 形式的动态代理, 其实现样例如下:
 
 ```
	import net.sf.cglib.proxy.Enhancer;
	import net.sf.cglib.proxy.InvocationHandler;
	
	import java.lang.reflect.Method;
	
	/**
	 * invocationHandler 代理逻辑调用器
	 */
	public class CglibInvocationHandler {
	
	
	    public static void main(String... args) {
	
	        Business business = new Business();
	        Enhancer enhancer = new Enhancer();
	        enhancer.setSuperclass(business.getClass());
	
	        enhancer.setCallback(new InvocationHandler() {
	            @Override
	            public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
	                Object rt = null;
	
	                System.out.println("do before business");
	                if (method.getReturnType().equals(String.class)) {
	                    rt = method.invoke(business, args);
	                } else {
	                    rt = "未知调用";
	                    /**
	                     * 不能直接调用proxy对象的method方法, 将会产生死循环
	                     * */
	                    // method.invoke(proxy, args);
	                }
	                System.out.println("do after business");
	                return rt;
	            }
	        });
	
	        Business businessProxy = (Business) enhancer.create();
	
	        businessProxy.doBusiness();
	
	
	    }
	
	    /**
	     * 业务类
	     */
	    private static class Business {
	
	        public Business() {
	        }
	
	        public String doBusiness() {
	            System.out.println("do business");
	            return "do business";
	        }
	    }
	}
 ```
 
  > 从样例代码中可以看出，和 **JDK原生动态代理** 一样，代理逻辑都是覆写 `InvocationHandler` 接口中的 `invoke` 方法实现的。需要注意的是，对原始方法的调用必须显式引入具体被代理的对象(业务对象)，对代理对象`proxy`直接使用`method.invoke(proxy, args)`进行方法调用将产生无限死循环!回顾一下**JDK原生动态代理**，应该也存在类似的问题。因此 **InvocationHandler** 在实际应用场景下并不常用，接下来介绍的 **MethodInterceptor** 将会解决这个问题。
 
### MethodInterceptor 代理逻辑调用器

- **MethodInterceptor** 代理逻辑调用器是最常用的代理方式，其调用样例如下:

	```
	import net.sf.cglib.proxy.Enhancer;
	import net.sf.cglib.proxy.MethodInterceptor;
	import net.sf.cglib.proxy.MethodProxy;
	
	import java.lang.reflect.Method;
	
	/**
	 * MethodInterceptor 代理逻辑调用器
	 */
	public class CglibMethodInterceptor {
	
	
	    public static void main(String... args) {
	
	        Business business = new Business();
	        Enhancer enhancer = new Enhancer();
	        enhancer.setSuperclass(business.getClass());
	
	        enhancer.setCallback(new MethodInterceptor() {
	            @Override
	            public Object intercept(
	                    Object obj,
	                    Method method,
	                    Object[] args,
	                    MethodProxy proxy) throws Throwable {
	                Object rt;
	                System.out.println("===\ndo before business");
	                if (method.getReturnType().equals(String.class)) {
	                    rt = proxy.invokeSuper(obj, args);          // 调用原始方法(被代理业务对象的方法)
	                } else {
	                    rt = "未知调用";
	                    System.out.println(rt);
	                }
	                System.out.println("do after business");
	                return rt;
	            }
	        });
	
	        Business businessProxy = (Business) enhancer.create();
	
	        System.out.println(businessProxy.doBusiness());
	        businessProxy.doBusiness("do business");
	
	
	    }
	
	    /**
	     * 业务类
	     */
	    private static class Business {
	
	        public Business() {
	        }
	
	        public String doBusiness() {
	            System.out.println("do business");
	            return "business return value";
	        }
	
	        public void doBusiness(String arg) {
	            System.out.println(arg);
	        }
	    }
	}
	```

  > 和 **InvocationHandler** 对比而言，其代理方法 **intercept** 的参数列表中多出一个 `MethodProxy proxy` 参数。`proxy` 参数是被代理类托管方法的封装。样例中 `proxy.invokeSuper(obj, args);` 这句代码就实现了对原始方法的调用，特别指出的是该调用并不依赖原始对象的引用（其中的obj对象是代理对象），也不会像 **InvocationHandler** 一样造成 `invoke 死循环风险`。

- 上面样例执行结果如下:

  ```
	===
	do before business
	do business
	do after business
	business return value
	===
	do before business
	未知调用
	do after business
  ```

> 码字太累，还剩几个调用器后续再补充完整(欢~迎~打~赏~) ^ ^

## 三、CGLIB 动态代理特点归纳和总结

简单列一下 **CGLIB** 代理的特点作为参考吧:

 1. CGLIB 的代理实现需要依赖第三方库;
 2. CGLIB 支持类级别的代理(相对于 **JDK 动态代理** 更为方便);
 3. CGLIB 只支持对 **非static且非final的public方法** 进行代理;
 4. CGLIB 支持多种代理逻辑调用器，可以实现丰富的代理，分发功能（后续会做更详细介绍）;
 5. 个人认为 CGLIB 代理实现上更直观简洁;

> 不难发现 **CGLIB** 的 **代理逻辑** 和 **代理装配逻辑** 也相互隔离，而装配逻辑可能在运行时才确定。因此 **CGLIB** 和 **JDK原生动态代理** 一样也是运行时实现代理生成的。但相较而言，使用 **CGLIB** 实现动态代理会更方便，更安全。
