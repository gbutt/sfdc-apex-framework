// provides mechanism to easily execute a list of handlers
// handlers are executed in the order in which they were added
public class TriggerHandlerExecutor {

	public TriggerHandler.TriggerContext triggerContext { get; set; }
	@TestVisible
	private Map<TriggerPhase, TriggerHandler.I[]> handlersByPhase { get; set; }
	//private Logger.I logger { get; set; }

	public TriggerHandlerExecutor() {
		this.handlersByPhase = new Map<TriggerPhase, TriggerHandler.I[]>();
		for (TriggerPhase phase : TriggerPhase.values()) {
			handlersByPhase.put(phase, new TriggerHandler.I[]{});
		}
		//this.logger = log.logger;
		this.triggerContext = new TriggerHandler.TriggerContext();
	}

	public void addHandler(TriggerPhase phase, TriggerHandler.I handler) {
		TriggerHandler.I[] handlers = handlersByPhase.get(phase);
		handlers.add(handler);
		handlersByPhase.put(phase,handlers);
	}

	public void init() {
		for (TriggerHandler.I handler : getHandlers()) {
			//log.logger = handler.getLogger();
			handler.init(triggerContext);
		}
		//log.logger = this.logger;
	}

	public void execute() {
		TriggerHandler.I[] handlers = getHandlers();
		try {
			for (TriggerHandler.I handler : handlers) {
				//log.logger = handler.getLogger();
				handler.execute();
			}
			for (TriggerHandler.I handler : handlers) {
				//log.logger = handler.getLogger();
				handler.finalize();
			}
		} catch (Exception ex) {
			log.error(ex);
			log.flush();
			throw ex;
		} finally {
			//log.logger = this.logger;
			log.flush();
		}

	}

	@TestVisible
	private TriggerHandler.I[] getHandlers() {
		return handlersByPhase.get(this.triggerContext.currentPhase);
	}

	/* PUBLIC STATIC METHODS */
	// provide an easy way to build a composite trigger handler
	public static Builder builder() {
		return new Builder();
	}

	/* HELPER CLASSES */
	public class Builder {

		public TriggerHandlerExecutor executor { get; set; }

		public Builder() {
			this.executor = new TriggerHandlerExecutor();
		}

		public Builder addHandler(TriggerPhase phase, TriggerHandler.I handler) {
			executor.addHandler(phase, handler);
			return this;
		}
		public TriggerHandlerExecutor build() {
			executor.init();
			return executor;
		}
	}	
}