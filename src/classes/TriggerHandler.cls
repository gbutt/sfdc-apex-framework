public abstract class TriggerHandler implements I {

	// an interface used by trigger handler decorators
	public interface I {
		// Returns the concrete class name of the TriggerHandler
		String getHandlerName();
		
		// Returns the trigger context
		TriggerContext getTriggerContext();
		
		// Returns the logger
		Logger.I getLogger();

		// initializes the trigger handler
		void init(TriggerContext triggerContext);
		
		// executes the trigger handler for the current phase (i.e. before insert)
		void execute();
		
		// finalizes the trigger handler
		void finalize();

		// returns false to block execution for the current phase
		Boolean shouldExecute();

		// returns a trigger handler decorated with the provided decorator
		TriggerHandler.I decorate(TriggerHandlerDecorator decorator);
	}

	/* ABSTRACT METHODS */
	// override to return the Type of your handler (i.e. MyHandler.class.getName())
	public virtual String getHandlerName() {
		return String.valueOf(this).substringBefore(':');
	}

	/* EXTENSIBLE METHODS - you can override these methods in your trigger handler */
	// returns true if your handler should execute. can be used to disable your handler programmatically
	public virtual Boolean shouldExecute() { return true; }
	// executes immediately before the init method
	protected virtual void preInit(TriggerContext triggerContext) {}
	// executes immediately after the init method
	protected virtual void postInit() {}
	// executes immediately before the execute method
	protected virtual void preExecute() {}
	// executes immediately after the execute method
	protected virtual void postExecute() {}
	// executes immediately before the finalize method
	protected virtual void preFinalize() {}
	// executes immediately after the finalize method
	protected virtual void postFinalize() {}
	// called during execute to handle the before insert phase
	protected virtual void beforeInsert() {}
	// called during execute to handle the before update phase
	protected virtual void beforeUpdate() {}
	// called during execute to handle the before delete phase
	protected virtual void beforeDelete() {}
	// called during execute to handle the after insert phase
	protected virtual void afterInsert() {}
	// called during execute to handle the after update phase
	protected virtual void afterUpdate() {}
	// called during execute to handle the after delete phase
	protected virtual void afterDelete() {}
	// called during execute to handle the after undelete phase
	protected virtual void afterUndelete() {}

	/* PUBLIC PROPERTIES */
	// logger implementation used by this handler
	// note you can also use the static methods on the log class
	public Logger.I logger { get; private set; }

	/* PRIVATE PROPERTIES */
	// the trigger context
	private TriggerContext triggerContext { get; set; }

	/* PUBLIC METHODS */
	// returns the trigger context for this handler
	public TriggerContext getTriggerContext() { 
		if (triggerContext == null) {
			triggerContext = new TriggerContext();
		}
		return triggerContext;
	}

	// returns the logger for this handler
	public Logger.I getLogger() { 
		return logger; 
	}

	// initializes this handler
	public void init(TriggerContext triggerContext) {
		preInit(triggerContext);
		this.triggerContext = triggerContext == null ? new TriggerContext() : triggerContext;
		this.logger = LoggerFactory.buildLogger(getHandlerName());
		postInit();
	}

	// this method will identifty and execute the appropriate handler method for the current phase
	public void execute() {
		if (isDisabled()) {
			log.info(getHandlerName() + ' is disabled');
			return;
		}

		log.debug('executing ' + getHandlerName() + ' for phase ' + getTriggerContext().currentPhase.name());
	
		preExecute();
		if (getTriggerContext().currentPhase == TriggerPhase.BEFORE_INSERT) {
			beforeInsert();
		} else if (getTriggerContext().currentPhase == TriggerPhase.AFTER_INSERT) {
			afterInsert();
		} else if (getTriggerContext().currentPhase == TriggerPhase.BEFORE_UPDATE) {
			beforeUpdate();
		} else if (getTriggerContext().currentPhase == TriggerPhase.AFTER_UPDATE) {
			afterUpdate();
		} else if (getTriggerContext().currentPhase == TriggerPhase.BEFORE_DELETE) {
			beforeDelete();
		} else if (getTriggerContext().currentPhase == TriggerPhase.AFTER_DELETE) {
			afterDelete();
		} else if (getTriggerContext().currentPhase == TriggerPhase.AFTER_UNDELETE) {
			afterUndelete();
		}
		postExecute();
	}

	// finalizes this handler
	public void finalize() {
		preFinalize();
		log.flush();
		postFinalize();
	}

	// returns a decorated handler
	public TriggerHandler.I decorate(TriggerHandlerDecorator decorator) {
		decorator.decoratedHandler = this;
		return decorator;
	}

	/* PRIVATE METHODS */
	// detect if the handler is currently disabled
	@TestVisible
	private Boolean isDisabled() {
		Boolean isDisabled = false;

		// custom disable logic
		isDisabled = !shouldExecute();
		// disabled by trigger settings
		isDisabled = isDisabled || TriggerHelper.isDisabled(getHandlerName());
		return isDisabled;
	}

	// encapulates the 'Trigger' keyword in apex
	public class TriggerContext {
		@TestVisible
		public SObject[] newRecords {
			get { 
				if (newRecords == null){
					newRecords = Trigger.new;
				}
				return newRecords;
			}
			private set;
		}
		@TestVisible
		public SObject[] oldRecords {
			get { 
				if (oldRecords == null) {
					oldRecords = Trigger.old; 
				}
				return oldRecords;
			}
			private set;
		}
		@TestVisible
		public Map<Id, SObject> newRecordsMap {
			get { 
				if (newRecordsMap == null) {
					newRecordsMap = Trigger.newMap; 
				}
				return newRecordsMap;
			}
			private set;
		}
		@TestVisible
		public Map<Id, SObject> oldRecordsMap {
			get { 
				if (oldRecordsMap == null) {
					oldRecordsMap = Trigger.oldMap; 
				}
				return oldRecordsMap;
			}
			private set;
		}
		@TestVisible
		public TriggerPhase currentPhase { 
			get {
				if (currentPhase == null) {
					currentPhase = detectCurrentPhase();
				}
				return currentPhase;
			}
			private set;
		}

		public TriggerContext() {}

		private TriggerPhase detectCurrentPhase() {
			if (!Trigger.isExecuting) {
				return TriggerPhase.UNKNOWN;
			}
			if (Trigger.isBefore) {
				if (Trigger.isInsert) {
					return TriggerPhase.BEFORE_INSERT;
				} else if (Trigger.isUpdate) {
					return TriggerPhase.BEFORE_UPDATE;
				} else if (Trigger.isDelete) {
					return TriggerPhase.BEFORE_DELETE;
				}
			} else if (Trigger.isAfter) {
				if (Trigger.isInsert) {
					return TriggerPhase.AFTER_INSERT;
				} else if (Trigger.isUpdate) {
					return TriggerPhase.AFTER_UPDATE;
				} else if (Trigger.isDelete) {
					return TriggerPhase.AFTER_DELETE;
				} else if (Trigger.isUndelete) {
					return TriggerPhase.AFTER_UNDELETE;
				}
			}
			return TriggerPhase.UNKNOWN;
		}
	}

}