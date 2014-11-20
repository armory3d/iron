package fox.core;

import composure.traits.AbstractTrait;

class FrameUpdater extends AbstractTrait {

	var updateTraits:Array<IUpdateable> = [];
	var lateUpdateTraits:Array<ILateUpdateable> = [];

	public function new() {
		super();
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addUpdateTrait(trait:IUpdateable) {
		updateTraits.push(trait);
	}
	
	@injectRemove
	public function removeUpdateTrait(trait:IUpdateable) {
		updateTraits.remove(trait);
	}

	@injectAdd({desc:true,sibl:false})
	public function addLateUpdateTrait(trait:ILateUpdateable) {
		lateUpdateTraits.push(trait);
	}
	
	@injectRemove
	public function removeLateUpdateTrait(trait:ILateUpdateable) {
		lateUpdateTraits.remove(trait);
	}
	
	public function update() {
		for(trait in updateTraits){
			trait.update();
		}

		for(trait in lateUpdateTraits){
			trait.update();
		}
	}
}
