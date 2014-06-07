package wings.core;

import composure.traits.AbstractTrait;

class FrameUpdater extends AbstractTrait {

	var updateTraits:Array<IUpdateTrait> = [];

	public function new() {
		super();
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addUpdateTrait(trait:IUpdateTrait) {
		updateTraits.push(trait);
	}
	
	@injectRemove
	public function removeUpdateTrait(trait:IUpdateTrait) {
		updateTraits.remove(trait);
	}
	
	public function update() {
		for(trait in updateTraits){
			trait.update();
		}
	}
}
