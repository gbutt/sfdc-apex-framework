public abstract class TriggerHandlerDecorator implements TriggerHandler.I {
	public TriggerHandler.I decoratedHandler {get;set;}

	public TriggerHandler.I decorate(TriggerHandlerDecorator decorator) {
		if (decorator.decoratedHandler != null) {
			throw new DecoratorException('This decorator instance is already decorating another trigger handler. Please create a new decorator.');
		}
		decorator.decoratedHandler = this;
		return decorator;
	}
	
	/* Delegated Methods */
	public String getHandlerName() { 
		return decoratedHandler.getHandlerName(); 
	}
	public TriggerHandler.TriggerContext getTriggerContext() { 
		return decoratedHandler.getTriggerContext(); 
	}
	public Logger.I getLogger() { 
		return decoratedHandler.getLogger(); 
	}

	/* Extensible Methods */
	public virtual Boolean shouldExecute() {
		// NOTE: this does not override the trigger handler's shouldExecute method. 
		// It is only used by decorators.
		// That is why we must call this method before executing the decorated handler.
		return true;
	}
	public virtual void init(TriggerHandler.TriggerContext triggerContext) {
		decoratedHandler.init(triggerContext);
	}
	public virtual void execute() {
		if (shouldExecute()) {
			decoratedHandler.execute();
		}
	}
	public virtual void finalize() {
		decoratedHandler.finalize();
	}

	public class DecoratorException extends Exception {}
}